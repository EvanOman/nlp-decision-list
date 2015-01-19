=comment
	This is my decision list class which contains the structure of the decision list along with all of the necessary utility functions.
=cut


package DecisionList;
use Switch;
use CollocationFactor;

#Here I define some enums which will serve a purpose throughout this class
use constant PREV 		=>	1;
use constant SURR		=>	2;
use constant NEXT		=>	3;
use constant PREV_1		=>	4;
use constant NEXT_1		=>	5;
use constant SENSE_1 	=>	"phone";
use constant SENSE_2 	=>	"product";
use constant NIL 		=>	-1;

#This is the initialer for the class
sub new
{
	my $class = shift;
	my $self = {
		_trainingFileName		=>	shift,
		_decisionList			=>	[],
		_collocationData		=>	[],
	};

=comment
	Note that the structure of the collocatrionData hashes is:
	hash = {
		"w1/w2" => {
				sense1 => count
				sense2 => count
		},
	.
	.
	.
	}
=cut

	bless $self, $class;

	#Parses the training data and populates the appropriate hashes
	$self->populateCollocationData($self->{_trainingFileName});

	#Now that we have all of the data collected, we can make our decision list and sort the factors according to their log likelihood
	$self->createDecisionList();

	return $self;
}

=comment
	Here is where we will parse the training set and populate the collocation data hashes. Based off of the Yarkowsky's paper I have decided to include the following collocational factors:
		-prev: Previous two words	(-2,-1 W)
		-surr: Surrounding words	(-1,+1 W)
		-next: Next two words		(+1,+2 W)
=cut
sub populateCollocationData
{
	my( $self ) = @_;
	my $filename = $_[1];

	open(MYFILE, $filename);
	my $lines = <MYFILE>;
	close(MYFILE);

	#Sets the topic
	$_ = $lines;

	#Translates everything to lower case
	tr/[A-Z]/[a-z]/;

	#Some useful variables
	my $sense;
	my $context;
	my @collocationArr = [];

	for my $type (PREV..NEXT_1)
	{
		push(@collocationArr, {});
	}

	#Based on the format of the given training data, we can loop through each "instance" which contains a hand tagged word sense along with context.
	#A note on the regex: +? gives a non-greedy match so we can go one tagset at a time rather than the overall <instance ... </instance> match
	for (m/<instance.+?<\/instance>/gms)
	{
		#Grabs the word sense in this instance
		if (m/senseid=\"(\w+)\"/gms)
		{
			$sense = $1;
			$self->{_totalOccurancesHash}{$sense}++;
		}
		else
		{
			print "PARSE ERROR, EXITING";
			return;
		}

		#Grabs the context sentence[s?]
		if (m/<context>(.+)<\/context>/gms)
		{
			$context = $1;

			#Cleans things up a bit
			$context =~ tr/([\,\"])/ $1 /;

			#Here we grab all of the words in a +/-2 window of the word line, again using the fact that the data is structured such that the instance of line that is of interest is wrapped in a <head></head>
			if ($context =~ m/\s+([^\s]+)\s+([^\s]+)\s+<head>line[s]?<\/head>\s+([^\s]+)\s+([^\s]+)/gms	)
			{
				#At this point we have:
				#	-(-2) word => $1
				#	-(-1) word => $2
				#	-(+1) word => $3
				#	-(+2) word => $4

				$collocationArr[PREV]{"$1\/$2"}{$sense}++;
				$collocationArr[SURR]{"$2\/$3"}{$sense}++;
				$collocationArr[NEXT]{"$3\/$4"}{$sense}++;
				$collocationArr[PREV_1]{"$2"}{$sense}++;
				$collocationArr[NEXT_1]{"$3"}{$sense}++;
			}
			else
			{
				print "PARSE ERROR, EXITING";
				return;
			}
		}
	}
	#Outputs the data array to the contex data object
	@{$self->{_collocationData}} = @collocationArr;
}

=comment
	Takes the collected collocation data and creates an array of collocation decision factor objects which are sorted by their log likelihood as a measure of the efficacy.
=cut
sub createDecisionList
{
	#Parse the data of all three collocation types and push the outgoing list into the master decision list
	my( $self ) = @_;
	my @decisionArr = ();

	#For each type, parse the collocation data
	for my $type (PREV..NEXT_1)
	{
		$self->parseCollocationData($type);
	}

	#Now we sort the master decision list by the log score of collocation factor objects
	@{$self->{_decisionList}} = sort {abs($b->getLogScore()) <=> abs($a->getLogScore())} @{$self->{_decisionList}};
}

=comment
	For the specified collocation type, add the factors to the global decision list
=cut
sub parseCollocationData
{
	my($self, $type) = @_;
	my %data = %{$self->{_collocationData}[$type]};
	my @factorArr = ();

	#First loop through 
	for my $words (keys %data)
	{
		#Here I perform a simple add one interpolation
		$data{$words}{${\SENSE_1}}++;
		$data{$words}{${\SENSE_2}}++;

		my $total = $data{$words}{${\SENSE_1}} + $data{$words}{${\SENSE_2}};

		#Now we can compute the log likelihood score:
		my $pNum = $data{$words}{${\SENSE_1}}/$total;	#Numerator probability
		my $pDen = $data{$words}{${\SENSE_2}}/$total;	#Denominator probability

		my $logScore = log($pNum/$pDen);

		#The sign of the log score tells us which probability was greater. If the sign is positive then the the log term was greater than 1 and thus the numerator was greater. A similar argument applies to the denominator. Thus I have implemented the below ternary that carries out the logic specified above
		my $sense = $logScore > 0 ? ${\SENSE_1} : ($logScore < 0 ? ${\SENSE_2} : ${\NIL});

		my $factor = new CollocationFactor($type, $words, $logScore, $sense);

		push(@{$self->{_decisionList}}, $factor);
	}
}

=comment
	Apply this instance's decision list to the given test data
=cut
sub classifyTestData
{
	my($self, $testFileName) = @_;

	open(MYFILE, $testFileName);
	my $lines = <MYFILE>;
	close(MYFILE);

	$_ = $lines;


	#Loop over each given instance
	for (m/<instance.+?<\/instance>/gms)
	{
		$instanceID = "";
		$answerWordSense = "";

		#Grabs the instance ID
		if (m/id=\"(.+?)\"/gms)
		{
			$instanceID = $1;
		}

		#Grabs the context sentence[s?]
		if (m/<context>(.+)<\/context>/gms)
		{
			$context = $1;

			#Cleans things up a bit
			$context =~ tr/([\,\"])/ $1 /;

			#Here we grab all of the words in a +/-2 window of the word line, again using the fact that the data is structured such that the instance of line that is of interest is wrapped in a <head></head>
			if ($context =~ m/\s+([^\s]+)\s+([^\s]+)\s+<head>line[s]?<\/head>\s+([^\s]+)\s+([^\s]+)/gms	)
			{
				#At this point we have:
				#	-(-2) word => $1
				#	-(-1) word => $2
				#	-(+1) word => $3
				#	-(+2) word => $4

				$answerWordSense = $self->applyDecisionList($1, $2, $3, $4);
			}
		}
		#If we made it here, then one of the factors must have applied. Thus we can simply write the answer to the standard I/O buffer, as directed
		print "<answer instance=\"$instanceID\" senseid=\"$answerWordSense\"\/>\n";
	}
}

=comment
	Actually loops through the sorted decision list and applies the most likely tag
=cut
sub applyDecisionList
{
	my($self, $one, $two, $three, $four) = @_;
	#Now we cycle through all of the possible factors, starting with the factors that had the highest log likelihood
	for my $factor (@{$self->{_decisionList}})
	{
		#We must handle each type of factor differently

		my $type = $factor->getType();
		my $words = $factor->getWords();
		my $wordSense = $factor->getWordSense();
		my $logLikelihood = $factor->getLogScore();

		if ($logLikelihood == 0)
		{
			#APPLY NIL TAG
			$answerWordSense = -1;

			#exit the loop, we found our tag
			return;
		}

		#Handle the current factor based on its type
		switch ($type)
		{
			case PREV
			{
				#Must match previous 2:
				my @wordsArr = split "\/", $words;
				if ($wordsArr[0] eq $one && $wordsArr[1] eq $two)
				{
					#APPLY TAG
					#exit the loop, we found our tag
					return $wordSense;
				}
			}
			case SURR
			{
				#Must match surrounding 2:
				my @wordsArr = split "\/", $words;
				if ($wordsArr[0] eq $two && $wordsArr[1] eq $three)
				{
					#APPLY TAG
					#exit the loop, we found our tag
					return $wordSense;
				}
			}
			case NEXT
			{
				#Must match the next 2:
				my @wordsArr = split "\/", $words;
				if ($wordsArr[0] eq $three && $wordsArr[1] eq $four)
				{
					#APPLY TAG
					#exit the loop, we found our tag
					return $wordSense;
				} 
			}
			case PREV_1
			{
				#Must match previous 1:
				if ($words eq $two)
				{
					#APPLY TAG
					#exit the loop, we found our tag
					return $wordSense;
				}
			}
			case NEXT_1
			{
				#Must match next 1:
				if ($words eq $three)
				{
					#APPLY TAG
					#exit the loop, we found our tag
					return $wordSense;
				}
			}
			else
			{
				#APPLY TAG
				#exit the loop, we found our tag
				return -1;
			}

		}
	}
}

=comment
	Outputs the decision list in a human readable manner
=cut
sub printDecisionTree
{
	my($self, $filename) = @_;
	open(my $fh, '>', $filename);

	print $fh "--------------------\n\n";

	my $counter = 0;
	for my $factor (@{$self->{_decisionList}})
	{
		my $score = $factor->getLogScore();
		print $fh "Log score: $score\n";
		my $words = $factor->getWords();
		my $wordSense = $factor->getWordSense();
		#Handle the current factor based on its type
		switch ($factor->getType())
		{
			case PREV
			{
				print $fh "If the previous two words are $words, then the word sense is $wordSense\n";
			}
			case SURR
			{
				print $fh "If the surrounding two words are $words, then the word sense is $wordSense\n";
			}
			case NEXT
			{
				print $fh "If the next two words are $words, then the word sense is $wordSense\n";
			}
			case PREV_1
			{
				print $fh "If the previous word is $words, then the word sense is $wordSense\n";
			}
			case NEXT_1
			{
				print $fh "If the next word is $words, then the word sense is $wordSense\n";
			}
		}
		print $fh "\n--------------------\n\n"
	}
	close $fh;

}

#Boiler plate class file ending
1;
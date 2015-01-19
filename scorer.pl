=comment 
	The goal of this script is to compare the output of decision-tree.pl with the key file.

	Usage: perl scorer.pl **TEST FILE** **KEY FILE**
=cut

#We assume here that the lines are in one to one correspondence(which they are)
main();

sub main 
{
	#Grabs the input params
	my $testFile = $ARGV[0];
	my $keyFile = $ARGV[1];

	#Get all of the senseids from the test file:
	@testAnswers = ();
	open(MYFILE, $testFile);
	my $lines = <MYFILE>;
	$_ = $lines;
	for (<MYFILE>)
	{
		if (m/senseid=(".*")/gms)
		{
			push @testAnswers, $1;
		}
	}
	close(MYFILE);

	#Get all of the senseids from the test file:
	@keyAnswers = ();
	open(MYFILE, $keyFile);
	$lines = <MYFILE>;
	$_ = $lines;
	for (<MYFILE>)
	{
		if (m/senseid=(".*")/gms)
		{
			push @keyAnswers, $1;
		}
	}
	close(MYFILE);

	my $right;
	my $total;
	my $arrSize = @testAnswers;

	for (my $i = 0; $i < $arrSize; $i++)
	{
		if ($testAnswers[$i] eq $keyAnswers[$i])
		{
			$right++;
		}
		$total++;
	}

	my $accuracy = $right/$total;

	print "This decision tree got $right correct out of $total total giving an overall accuracy of $accuracy%.";
}
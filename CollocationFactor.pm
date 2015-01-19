=comment
	This class contains the structure of a single collocational factor. There are three possible types of collocation factors that I haver chosen to implement:
		1. prev: The previous 2 words
		2. surr: The surrounding 2 words
		3. next: The next 2 words
=cut



#Unofficial enum for the collocation types:
#$prev = 1;
#$surr = 2;
#$next = 3;
package CollocationFactor;
sub new
{
	my $class = shift;
	my $self = {
		_type		=>	shift,
		_words		=>	shift,		#Contains the collocation data for the (-2,-1 W) case
		_logScore	=>	shift,		#Container for the decision list
		_wordSense	=>	shift,		#The winning word sense, could be NIL(-1)
	};

	bless $self, $class;
	return $self;
}


sub getType
{
	my( $self ) = @_;
	return $self->{_type};
}

sub getWords
{
	my( $self ) = @_;
	return $self->{_words};
}

sub getLogScore
{
	my( $self ) = @_;
	return $self->{_logScore};
}


sub getWordSense
{
	my( $self ) = @_;
	return $self->{_wordSense};
}

1;
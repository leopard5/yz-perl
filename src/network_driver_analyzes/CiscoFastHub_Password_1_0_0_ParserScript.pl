#! /usr/local/bin/perl

sub GetReadOnlyCommunity
{
	my($config) = @_;
	my(@array) = ();

	# Device omits the ro string from the configuration if it's set to "public"
	if ($config =~ /Read community string: (\S+)/)
	{
		$array[0] = $1;
	} else {
		$array[0] = "public";
	}

	return @array;
}

sub GetReadWriteCommunity
{
	my($config) = @_;
	my(@array) = ();

	# Device omits the rw string from the configuration if it's set to "private"
	if ($config =~ /Write community string: (\S+)/)
	{
		$array[0] = $1;
	} else {
		$array[0] = "private";
	}

	return @array;
}

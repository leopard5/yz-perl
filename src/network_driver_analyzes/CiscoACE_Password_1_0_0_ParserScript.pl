#! /usr/local/bin/perl

sub GetReadOnlyCommunity
{
	my($config) = @_;
	my(@array) = ();

	$count = 0;
	while ($config =~ /snmp-server community (\S+) group Network-Monitor/igc)
	{
		$array[$count] = $1;
		$array[$count] =~ s/\"//g;
		$array[$count+1] = $3;
		$count = $count + 2;
	}
	
	return @array;	
}


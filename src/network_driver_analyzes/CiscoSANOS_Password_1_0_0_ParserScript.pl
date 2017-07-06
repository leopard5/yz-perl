#! /usr/local/bin/perl

sub GetReadOnlyCommunity
{
	my($config) = @_;
	my(@array) = ();

	$count = 0;
	while ($config =~ /snmp-server community (\S+) .*group network-operator.*/igc)
	{
		$array[$count] = $1;
		$array[$count] =~ s/\"//g;
		$array[$count+1] = $3;
		$count = $count + 2;
	}
	
	return @array;	
}

sub GetReadWriteCommunity
{
	my($config) = @_;
	my(@array) = ();

	$count = 0;
	while ($config =~ /snmp-server community (\S+) .*group network-admin.*/igc)
	{
		$array[$count] = $1;
		$array[$count] =~ s/\"//g;
		$array[$count+1] = $3;
		$count = $count + 2;	
	}
	
	return @array;	
}


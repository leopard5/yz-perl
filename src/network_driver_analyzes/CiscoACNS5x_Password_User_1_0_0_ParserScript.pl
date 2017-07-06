#! /usr/local/bin/perl

sub GetReadOnlyCommunity
{
	my($config) = @_;
	my(@array) = ();

	$count = 0;
	my %seen = {};
	while ($config =~ /snmp-server community (\S+)\s*?\n/isg )
	{
		next if $seen{$1};
		$seen{$1}++;		$array[$count] = $1;
		$array[$count] =~ s/\"//g;
		$count++;
	}
	return @array;	
}

sub GetReadWriteCommunity
{
	my($config) = @_;
	my(@array) = ();
	my %seen = {};
	$count = 0;

	while ($config =~ /snmp-server community (\S+)\s*?RW\s*?\n/isg)
	{
		next if $seen{$1};
		$seen{$1}++;
		$array[$count] = $1;
		$array[$count] =~ s/\"//g;
		$count++;	
	}
	
	return @array;	
}


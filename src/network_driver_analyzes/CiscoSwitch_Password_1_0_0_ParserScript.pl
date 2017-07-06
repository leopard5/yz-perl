#! /usr/local/bin/perl

sub GetReadOnlyCommunity
{
	my($config) = @_;
	my(@array) = ();

	$count = 0;
	while ($config =~ /snmp-server community (\S+) (view \S+ )?RO\s+(\d*)/igc)
	{
		$array[$count] = $1;
		$array[$count] =~ s/\"//g;
		$array[$count+1] = $3;
		$count = $count + 2;
	}
	pos($config) = 0;
	if($config !~ /no snmp-server community public/i && $config !~ /\nsnmp-server community \"*public\"* +RO/i)
	{
		$array[$count] = "public";
		$array[$count] =~ s/\"//g;
		$array[$count+1] = "";
		$count = $count + 2;
	}
	
	return @array;	
}

sub GetReadWriteCommunity
{
	my($config) = @_;
	my(@array) = ();

	$count = 0;
	while ($config =~ /snmp-server community (\S+) (view \S+ )?RW\s+(\d*)/igc)
	{
		$array[$count] = $1;
		$array[$count] =~ s/\"//g;
		$array[$count+1] = $3;
		$count = $count + 2;	
	}
	pos($config) = 0;
	if($config !~ /no snmp-server community private/i && $config !~ /\nsnmp-server community \"*private\"* +RO/i)
	{
		$array[$count] = "private";
		$array[$count] =~ s/\"//g;
		$array[$count+1] = "";
		$count = $count + 2;
	}
	
	return @array;	
}


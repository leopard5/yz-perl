#! /usr/local/bin/perl

sub GetDNS
{
	my($config) = @_;
	my(@array) = ();

	$count = 0;
	while ($config =~ /ip name-server (\S+)/gc)
	{
		$array[$count] = $1;
		$count++;
	}

	return @array;
}

sub GetDomains
{
	my($config) = @_;
	my(@array) = ();
	$count = 0;
	
	while ($config =~ /ip domain[ -]name +(\S+)/gc)
	{
		$array[$count] = $1;
		$array[$count] =~ s/\"//g;
		$count++;
	}

	pos($config) = 0;
	while ($config =~ /ip domain[ -]list +(\S+)/gc)
	{
		$array[$count] = $1;
		$array[$count] =~ s/\"//g;
		$count++;
	}
 
	pos($config) = 0;
	while ($config =~ /domain name (\S+)/gc)
	{
		$array[$count] = $1;
		$array[$count] =~ s/\"//g;
		$count++;
	}
	return @array;
}

sub GetDefaultGateway
{
	my($config) = @_;
	my(@array) = ("");
	my($count) = 0;

	if ($config =~ /ip default-gateway (\S+)/)
	{
		$array[0] = $1;
	}

	return @array;
}

sub GetPortInfo
{
	my($config) = @_;

	my(@portNames) = ( "startnames" );
	my(@portAllows) = ( "startallows" );
	my(@portTypes) = ( "starttypes" );
	my(@portStatus) = ( "startstatus" );
	my(@portDescription) = ( "startdescription" );
	my(@portAddresses) = ( "startaddresses" );
	my(@portMasks) = ( "startmasks" );
	my(@portMACAddresses) = ( "startmacs" );
	my(@portVLANs) = ( "startvlans" );
	my(@portDuplexes) = ( "startduplex" );
	my(@portSpeeds) = ( "startspeed" );
	my(@portCounts) = ( "startcounts" );
	my(@secondaryAddresses) = ( "startsecaddrs" );
	my(@secondaryMasks) = ( "startsecmasks" );

	my($count) = 1;
	my($secondaryIndex) = 1;
	my($tempcount) = 0;
	my($single_inf) = 0;

	my(@array) = ();

	while ($config =~ /(^|\n)[\s]*interface ([\S ]+)([\S\s]+?\n\n)/gc)
	{
		$interfaceConfig = $3;

		$portNames[$count] = $2;
		$portTypes[$count] = $portNames[$count];
		$portTypes[$count] =~ s/(\S+)?([A-Za-z]+) ?[0-9.\/]+/$1$2/;
		$portTypes[$count] =~ s/ethernet/Ethernet/;

		$portAllows   [$count] = "GenericPort_1_0_0";
		$portAddresses[$count] = "";
		$portMasks    [$count] = "";
		$portCounts   [$count] = 0;
		$portDuplexes [$count] = "";
		$portSpeeds   [$count] = "";
		$portDescription [$count] = "";
		$portMACAddresses[$count] = "";

		# Obtain Status
		$portStatus[$count] = "Configured Up";
		if($interfaceConfig =~ /shutdown/)
		{
			$portStatus[$count] = "Administratively Down";
		}
			
		$portDuplexes[$count] = "auto-negotiated" if $portTypes[$count] =~ /Ethernet/;
		if($interfaceConfig =~ /\n\s+duplex (\S+)(\n|$)/)
		{
			my $duplex = $1;
			if ($duplex ne "auto")
			{
				$portDuplexes[$count] = $duplex;
			}
		}

		$portSpeeds[$count] = "auto-negotiated" if $portTypes[$count] =~ /Ethernet/;
		if ($interfaceConfig =~ /\n\s+speed (\S+)(\n|$)/)
		{
			my $speed = $1;
			if ($speed ne "auto")
			{
				$portSpeeds[$count] = $speed;
			}
		}
			
		# Store IP addresses
		if ($interfaceConfig =~ /[\r\n] *ip address\s+(\S+)\s+(\S+)/)
		{
			$portAllows   [$count] = "IPPort_1_0_0";
			$portAddresses[$count] = $1;
			$portMasks    [$count] = $2;
		}

		$count++;
	}

	# close arrays
	$portNames[$count] = "endnames";
	$portAllows[$count] = "endallows";
	$portTypes[$count] = "endtypes";
	$portStatus[$count] = "endstatus";
	$portDescription[$count] = "enddescription";
	$portAddresses[$count] = "endaddresses";
	$portMasks[$count] = "endmasks";
	$portMACAddresses[$count] = "endmacs";
	$portVLANs[$count] = "endvlans";
	$portDuplexes[$count] = "endduplex";
	$portSpeeds[$count] = "endspeed";
	$portCounts[$count] = "endcounts";
	$secondaryAddresses[$secondaryIndex] = "endsecaddrs";
	$secondaryMasks[$secondaryIndex] = "endsecmasks";

	# combine arrays
	push @array, @portNames;
	push @array, @portAllows;
	push @array, @portTypes;
	push @array, @portStatus;
	push @array, @portDescription;
	push @array, @portAddresses;
	push @array, @portMasks;
	push @array, @portMACAddresses;
	push @array, @portVLANs;
	push @array, @portDuplexes;
	push @array, @portSpeeds;
	push @array, @portCounts;
	push @array, @secondaryAddresses;
	push @array, @secondaryMasks;

	return @array;
}

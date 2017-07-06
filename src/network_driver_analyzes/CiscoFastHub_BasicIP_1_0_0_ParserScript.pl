#! /usr/local/bin/perl

sub GetDNS
{
	my($config) = @_;
	my(@array) = ();
	
	# Not supported by a Hub
	return @array;
}

sub GetDomains
{
	my($config) = @_;
	my(@array) = ();

	# Not supported by a Hub
	return @array;
}

sub GetDefaultGateway
{
	my($config) = @_;
	my(@array) = ( "" );
	my($count) = 0;

	if ($config =~ /Default Gateway: (\S+)/)
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
	my(@portCounts) = ( "startcounts" );
	my(@secondaryAddresses) = ( "startsecaddrs" );
	my(@secondaryMasks) = ( "startsecmasks" );

	my($count) = 1;
	my($secondaryIndex) = 1;
	my($tempcount) = 0;
	my($single_inf) = 0;

	my(@array) = ();
	
	if ($config =~ /IP Address: (\S+)/) {
		# We need to list the device's own IP address; it is not explicitly associated with an interface
		$portAddresses  [$count] = $1;
		$portNames      [$count] = "ip interface";
		$portTypes      [$count] = "Ethernet";
		$portAllows     [$count] = "IPPort_1_0_0";
		$portDescription[$count] = "Internal IP address";
		$portStatus     [$count] = "Configured Up";
		$portCounts     [$count] = 0;
		
		if ($config =~ /Subnet Mask: (\S+)/) {
			$portMasks[$count] = $1;
		} else {
			$portMasks[$count] = "";
		}
		$count++;
	}

	while ($config =~ /\n[\s]*interface (.*)/gc)
	{
		$portNames[$count] = $1;

		$portTypes[$count] = $portNames[$count];
		$portTypes[$count] =~ s/([A-Za-z]+) [0-9.\/]+/$1/;

		$portAllows[$count] = "GenericPort_1_0_0";

		$portAddresses[$count] = "";
		$portMasks[$count] = "";
		$portCounts[$count] = 0;

		$interfaceStart = pos($config);

		if ($config =~ /\n!/gc)
		{
			$interfaceEnd = pos($config);
			$interfaceConfig = substr($config, $interfaceStart, $interfaceEnd - $interfaceStart);

			$noipaddress = 0;
			if ($interfaceConfig =~ /(no )?ip(v4)? address/)
			{
				if ($1 eq "no ")
				{
					$noipaddress = 1;

					$portAddresses[$count] = "";
					$portMasks[$count] = "";
				}
			}

			# Obtain Status
			$status = "Configured Up";
			if($interfaceConfig =~ /\n\s+shutdown/)
			{
				$status = "Administratively Down";
			}
			$portStatus[$count] = $status;
			
			# Obtain description
			$portDescription[$count] = "";
			if($interfaceConfig =~ /description ([ \S]+)/ ||
				 $interfaceConfig =~ /Description: ([ \S]+)/)
			{
				$portDescription[$count] = $1;
				$portDescription[$count] =~ s/,$//;
			}

			if ($noipaddress == 0)
			{
				pos($interfaceConfig) = 0;

				$tempcount = 0;

				# Store secondary addresses
				while ($interfaceConfig =~ /ip(v4)? address\s+(\S+)\s+(\S+)/gc)
				{
					$portAllows[$count] = "IPPort_1_0_0";

					$tempAddress = $2;
					$tempMask = $3;

					if ($interfaceConfig =~ /\G secondary/gc)
					{
						$secondaryAddresses[$secondaryIndex] = $tempAddress;
						$secondaryMasks[$secondaryIndex] = $tempMask;
						$tempcount++;
						$secondaryIndex++;
					}
					else
					{
						$portAddresses[$count] = $tempAddress;
						$portMasks[$count] = $tempMask;
					}

					$portCounts[$count] = $tempcount;
				}

				# Store HSRP information
				pos($interfaceConfig) = 0;
				$tempCount = 0;

				while($interfaceConfig =~ /standby( \d+)? ip (\S+)/gc)
				{
					$portAllows[$count] = "IPPort_1_0_0";

					$tempGroup   = $1; # Would be nice to list the group name; future expansion?
					$tempAddress = $2;
					$tempMask = $portMasks[$count];

					$secondaryAddresses[$secondaryIndex] = $tempAddress;
					$secondaryMasks[$secondaryIndex] = $tempMask;
					$tempCount++;
					$secondaryIndex++;
				

				}

				$portCounts[$count] = int($portCounts[$count] + $tempCount);
			}
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
	push @array, @portCounts;
	push @array, @secondaryAddresses;
	push @array, @secondaryMasks;

	return @array;
}

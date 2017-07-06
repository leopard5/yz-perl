#! /usr/local/bin/perl

sub GetDNS
{
	my($config) = @_;
	my(@array) = ();

	$count = 0;
	if($config =~ /ip name-server/){
		while ($config =~ /ip name-server (\S+)/gc)
		{
			$array[$count] = $1;
			$count++;
		}
	}
	
	return @array;
}

sub GetDomains
{
	my($config) = @_;
	my(@array) = ();
	my $count = 0;
	my %seen = {};
	
	while ($config =~ /ip domain-name +(\S+)/igc)
	{
		next if $seen{$1};
		$seen{$1}++;
		$array[$count] = $1;
		$array[$count] =~ s/\"//g;
		$count++;
	}
	return @array;
}

sub GetDefaultGateway
{
	my($config) = @_;
	my(@array) = ( "" );
	my($count) = 0;

	if ($config =~ /ip route 0.0.0.0 0.0.0.0 (\S+)/)
	{
		$array[0] = $1;
	}
	elsif ($config =~ /ip default-gateway (\S+)/)
	{
		$array[0] = $1;
	}
	elsif ($config =~ /route ipv4 0.0.0.0\/32 (\S+)/)
	{
		$array[0] = $1;
	}

	elsif ($config =~ /route ipv4 0.0.0.0 0.0.0.0 (\S+)/)
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

	my %extraVlans = ();
    my $defaultVLAN = "";

    if($config =~ /switchport access vlan/){
        $defaultVLAN = "VLAN1";
        $extraVlans{$defaultVLAN} = "true";
    }elsif($config =~ /interface VLAN1/)
	{
		$defaultVLAN = "VLAN1";
		$extraVlans{$defaultVLAN} = "false";
	}

	while ($config =~ /\n[\s]*interface ([\S ]+)/gc)
	{
		$portNames[$count] = $1;

		$portTypes[$count] = $portNames[$count];
		$portTypes[$count] =~ s/(\S+)?([A-Za-z]+) ?[0-9.\/]+/$1$2/;
		$portTypes[$count] =~ s/GigabitEthernet/GigEthernet/; # Correct port type to agree with model

        if($portTypes[$count] =~ /Vlan/i)
        {
            $portNames[$count] =~ s/Vlan/VLAN/;
            $portTypes[$count] =~ s/Vlan/VLAN/;
            $extraVlans{$portNames[$count]} = "false";
            if($count == 1){
                $defaultVLAN = "VLAN1";
            }
        }

		$portAllows[$count] = "GenericPort_1_0_0";

		$portAddresses[$count] = "";
		$portMasks[$count] = "";
		$portCounts[$count] = 0;
        $portDuplexes[$count] = "";
        $portSpeeds[$count] = "";

		$interfaceStart = pos($config);

		if ($config =~ /\n\s*exit/gc)
		{
			$interfaceEnd = pos($config);
			$interfaceConfig = substr($config, $interfaceStart, $interfaceEnd - $interfaceStart);

			# Obtain description
			$portDescription[$count] = "";
			if($interfaceConfig =~ /\n\s+description ([ \S]+)/)
			{
				$portDescription[$count] = $1;
				
				$interfaceConfig =~ s/\n\s+description [ \S]+//;
			}

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
			$status = "Administratively Down";
			if($interfaceConfig =~ /shutdown/)
			{
				if($interfaceConfig =~ /no +shutdown/)
				{
					$status = "Configured Up";
				}
			}
			else
			{
				$status = "Configured Up";
			}
			$portStatus[$count] = $status;
			
			$portVLANs[$count] = "";
            if($portTypes[$count] ne "VLAN")
            {
			    $portVLANs[$count] = "$defaultVLAN";
            }
			if($interfaceConfig =~ /switchport access vlan (\S+)/)
			{
				my $vlanname = "VLAN$1";
				$portVLANs[$count] = $vlanname;

				if ($extraVlans{$vlanname} ne "false")
				{
					$extraVlans{$vlanname} = "true";
				}
			}
			elsif($interfaceConfig =~ /encapsulation dot1Q (\S+)/)
			{
				my $vlanname = "VLAN$1";
				$portVLANs[$count] = $vlanname;
				if ($extraVlans{$vlanname} ne "false")
				{
					$extraVlans{$vlanname} = "true";
				}
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
			$portMACAddresses[$count] = "";
			
			if ($noipaddress == 0)
			{
				pos($interfaceConfig) = 0;

				$tempcount = 0;

				# Store secondary addresses
				while ($interfaceConfig =~ /[\r\n] *ip(v4)? address\s+(\S+)\s+(\S+)/gc)
				{
					$portAllows[$count] = "IPPort_1_0_0";

					$tempAddress = $2;
					$tempMask = $3;

					# Safety check for ensuring we only have IPv4 addresses
					if($tempAddress !~ /^\d+\.\d+\.\d+\.\d+$/ || $tempMask !~ /^\d+\.\d+\.\d+\.\d+$/)
					{
						$tempAddress = "";
						$tempMask = "";
					}

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

    # Look for management port info
    if($config =~ /\![\r\n]+ip address (\d+\.\d+\.\d+\.\d+) +(\d+\.\d+\.\d+\.\d+) *[\r\n]+(ip default-gateway|\!)/){
			$portNames[$count] = "Management";
			$portAllows[$count] = "IPPort_1_0_0";
			$portTypes[$count] = "Loopback";
			$portStatus[$count] = "Configured Up";
			$portDescription[$count] = "";
			$portAddresses[$count] = "$1";
			$portMasks[$count] = "$2";
			$portMACAddresses[$count] = "";
			$portVLANs[$count] = "";
			$portDuplexes[$count] = "";
			$portSpeeds[$count] = "";
			$portCounts[$count] = 0;
			
			$count++;
    }
	
	my $extraVlan;
	foreach $extraVlan (keys %extraVlans)
	{

		if ($extraVlans{$extraVlan} eq "true")
		{
			$portNames[$count] = $extraVlan;
			$portAllows[$count] = "GenericPort_1_0_0";
			$portTypes[$count] = "VLAN";
			$portStatus[$count] = "Configured Up";
			$portDescription[$count] = "";
			$portAddresses[$count] = "";
			$portMasks[$count] = "";
			$portMACAddresses[$count] = "";
			$portVLANs[$count] = "";
			$portDuplexes[$count] = "";
			$portSpeeds[$count] = "";
			$portCounts[$count] = 0;
			
			$count++;
		}
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

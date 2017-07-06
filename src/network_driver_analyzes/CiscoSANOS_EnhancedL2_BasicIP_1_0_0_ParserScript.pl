#! /usr/local/bin/perl

sub GetDNS
{
	my($config) = @_;
	my(@array) = ();

	$count = 0;
	if($config =~ /ip name-server/){
		while ($config =~ /ip name-server ([\S ]+)/gc)
		{
			foreach (split(/ /,$1)) {
				$array[$count] = $_;
				$count++;
			}
		}
	}
	elsif($config =~ /domain name-server/)  ## support for IOS XR
	{	
		while ($config =~ /domain name-server (\S+)/gc)
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
	elsif ($config =~ /router static[\n\S\s ]+?0\.0\.0\.0\/0 ([\d\.]+)/)
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
    }elsif($config =~ /interface VLAN1/i)
	{
		$defaultVLAN = "VLAN1";
		$extraVlans{$defaultVLAN} = "false";
	}

	while ($config =~ /\n[\s]*interface ([\S ]+)/gc)
	{
		$portNames[$count] = $1;

		$portTypes[$count] = $portNames[$count];
		$portTypes[$count] =~ s/mgmt/FastEthernet/;
		$portTypes[$count] =~ s/(\S+)?([A-Za-z]+) ?[0-9.\/]+/$1$2/;

        if($portTypes[$count] =~ /Vlan/i)
        {
            $portNames[$count] =~ s/Vlan/VLAN/;
            $portTypes[$count] =~ s/Vlan/VLAN/;
            $extraVlans{$portNames[$count]} = "false";
            if($count == 1){
                $defaultVLAN = "VLAN1";
            }
        }
	if ($portTypes[$count] eq "fc") {
		$portTypes[$count] = "FiberChannel";
	}
	
		$portTypes[$count] = "Channel" if ($portTypes[$count] =~ /channel/);
		$portTypes[$count] = "Tunnel" if ($portTypes[$count] =~ /tunnel/);

		$portAllows[$count] = "GenericPort_1_0_0";

		$portAddresses[$count] = "";
		$portMasks[$count] = "";
		$portCounts[$count] = 0;
        $portDuplexes[$count] = "";
        $portSpeeds[$count] = "";
        
        	$portStatus[$count] = "Configured Up";
			$portDescription[$count] = "";
			$portMACAddresses[$count] = "";
    

		$interfaceStart = pos($config);
		if ($config =~ /(\n\n|\ninterface|\n\s*$)/gc)
		{
			# Backup, so that at least one \n is available for the next loop iteration
			pos($config) -= length($1);
			
			$interfaceEnd = pos($config);
			my $interfaceConfig = substr($config, $interfaceStart, $interfaceEnd - $interfaceStart);

			# Obtain description
			$portDescription[$count] = "";
			if($interfaceConfig =~ /\n\s*(switchport )?description ([ \S]+)/)
			{
				$portDescription[$count] = $2;
			}

			# Obtain Status
			# mgmt port configuration does not show "no shutdown" if it is configured up
			if ($portNames[$count] =~ /(mgmt|channel)/)
			{
				$status = "Configured Up";
				if($interfaceConfig =~ /\n\s*shutdown/)
				{
					$status = "Administratively Down";
				}
			} else {
				$status = "Administratively Down";
				if($interfaceConfig =~ /\n\s*no +shutdown/)
				{
					$status = "Configured Up";
				}
			}
			$portStatus[$count] = $status;
			
			$portVLANs[$count] = "";
            if($portTypes[$count] ne "VLAN" && $interfaceConfig !~ /switchport mode trunk/)
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

			$portDuplexes[$count] = "auto-negotiated";
			if($interfaceConfig =~ /\n\s*(switchport )?duplex (\S+)/)
			{
				my $duplex = $2;
				if ($duplex ne "auto")
				{
					$portDuplexes[$count] = $duplex;
				}
			}

			$portSpeeds[$count] = "auto-negotiated";
			if ($interfaceConfig =~ /\n\s*(switchport )?speed (\S+)/)
			{
				my $speed = $2;
				if ($speed ne "auto")
				{
					$portSpeeds[$count] = $speed;
					$portSpeeds[$count] =~ s/000/G/;
				}
			}
			$portMACAddresses[$count] = "";
			
			$portAddresses[$count] = "";
			$portMasks[$count] = "";
			
			pos($interfaceConfig) = 0;

			$tempcount = 0;
			my $nrinterfaces = 0;

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

					if ($nrinterfaces > 0)
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
						$nrinterfaces++;
					}

					$portCounts[$count] = $tempcount;
				}

				#### parse ipv6 addresses
				pos($interfaceConfig) = 0;
				$tempCount = 0;

				while($interfaceConfig =~ /[\r\n] *ipv6 address\s+([a-fA-Z0-9:\.]+)\/(\d{1,3})/gc)
				{
					$tempAddress = $1;
					$tempMask = $2;
					
					$portAllows[$count] = "IPPort_1_0_0";

					if ($nrinterfaces > 0)
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
						$nrinterfaces++;
					}

					$portCounts[$count] = $tempcount;
				}
				$portCounts[$count] = int($portCounts[$count] + $tempCount);
			}

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

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
	elsif ($config =~ /ipv6 route ::\/0 (\S+)/)
	{
		$array[0] = $1;
	}
	return @array;
}

sub GetPortInfo
{
	my($config, $power) = @_;

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
		$portTypes[$count] =~ s/(\S+)?([A-Za-z]+) ?[0-9.\/]+/$1$2/;

        # Look for power, absolute power.
        my $abbr = &getPortAbbr($portNames[$count]);
        if($power =~ /$abbr/)
        {
            $portTypes[$count] = "POE-" . $portTypes[$count];
        }

        if($portTypes[$count] =~ /Vlan/i)
        {
            $portNames[$count] =~ s/Vlan/VLAN/;
            $portTypes[$count] =~ s/Vlan/VLAN/;
            $extraVlans{$portNames[$count]} = "false";
            if($count == 1){
                $defaultVLAN = "VLAN1";
            }
        }
        elsif( $portTypes[ $count ] =~ /GigabitEthernet/ )
        {
            $portTypes[ $count ] = "GigEthernet";
        }
        elsif( $portTypes[ $count ] =~ /Serial.*/ )
        {
            $portTypes[ $count ] = "Serial";
        }
        elsif( $portTypes[ $count ] =~ /BVI/ )
        {
            $portTypes[ $count ] = "Bridge";
        }

		$portAllows[$count] = "GenericPort_1_0_0";

		$portAddresses[$count] = "";
		$portMasks[$count] = "";
		$portCounts[$count] = 0;
        $portDuplexes[$count] = "";
        $portSpeeds[$count] = "";

		$interfaceStart = pos($config);

		if ($config =~ /\n!/gc)
		{
			$interfaceEnd = pos($config);
			$interfaceConfig = substr($config, $interfaceStart, $interfaceEnd - $interfaceStart);

			# Determine if port is trunking
			#if($interfaceConfig =~ /switchport (mode )?trunk/)
			#{
			#	$portTypes[$count] .= "Trunk";
			#}
			# Obtain description
			$portDescription[$count] = "";
			if($interfaceConfig =~ /\n\s+description ([ \S]+)/)
			{
				$portDescription[$count] = $1;
				
				$interfaceConfig =~ s/\n\s+description [ \S]+//;
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
			elsif($interfaceConfig =~ /switchport trunk native vlan (\S+)/)
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
			if($interfaceConfig =~ /half-duplex/)
			{
				$portDuplexes[$count] = "half";
			} elsif ($interfaceConfig =~ /full-duplex/)
			{
				$portDuplexes[$count] = "full";
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
						 
				pos($interfaceConfig) = 0;

				$tempcount = 0;

				# Store secondary addresses
				# ipv6 address FEC0::10/64
				# ipv6 address FEC0::/64 anycast
 				# ipv6 address FEC0::1/64 eui-64
 				# ipv6 address MyPrefix FEC0::1/64 eui-64
 				# ipv6 address FE80::66 link-local
				#while ($interfaceConfig =~ /[\r\n] *ip(v4|v6)? address (\S+) ?(\S+)?[\r\n]/gc)
				while ($interfaceConfig =~ / *ip(v4|v6)? address (.*)[\r\n]/gc)
				{
					$portAllows[$count] = "IPPort_1_0_0";					
					($tempAddress, $tempMask, $secondary) = parse_ip($2);
					next if(! $tempAddress);
					
					if (! $secondary && $portAddresses[$count] eq '' )
					{
						# First non-secondary IP becomes the first IP
						$portAddresses[$count] = $tempAddress;
						$portMasks[$count] = $tempMask;
					}
					else
					{
						# all other becomes secondary IP
						$secondaryAddresses[$secondaryIndex] = $tempAddress;
						$secondaryMasks[$secondaryIndex] = $tempMask;
						$tempcount++;
						$secondaryIndex++;
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
					$tempcount++;
					$secondaryIndex++;				
				}

				$portCounts[$count] = int($portCounts[$count] + $tempCount);			
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

sub parse_ip
{
	my($line) = @_;
				#1 ip address 10.255.2.2 255.255.255.0
				#2 ip address 10.255.1.2 255.255.255.0 secondary
				#3 ipv6 address FEC0::10/64
				#4 ipv6 address FEC0::/64 anycast
 				#5 ipv6 address FEC0::1/64 eui-64
 				#6 ipv6 address MyPrefix FEC0::1/64 eui-64
 				#7 ipv6 address FE80::66 link-local
				
	if($line =~ / *(\d+\.\d+\.\d+\.\d+) (\d+\.\d+\.\d+\.\d+)( secondary)?/i)
	{
		#1, #2
		return ($1, $2, ($3 eq ' secondary'));
	}
	if($line =~ /(\S+ )?([a-f0-9:\.]+)\/(\d{1,3})( \S+)?/i)
	{
		#3, #4, #5, #6
		if($4 ne ' eui-64') # skip dynamic ip		
		{			
			return ($2, $3, 0);
		}		
	} 
	elsif ($line =~ /(\S+) link-local/i)
	{
		#7
		$addr = $1;
		return ($1, "64", 0); #default mask 64	
	}
	return ();
}

sub getPortAbbr
{
    my ($abbr) = @_;

    my $expanded = $abbr;
    
    if ($abbr =~ /([a-zA-Z]+)([\d\/]+)/)
    {
        my $pt = $1;
        my $lowerpt = lc($pt);
        my $num = $2;
    
        if ($lowerpt eq "fastethernet")
        {
            $pt = "Fa";
        }
        elsif ($lowerpt eq "vlan")
        {
            $pt = "VLAN";
        }
        elsif ($lowerpt eq "gigabitethernet")
        {
            $pt = "Gi";
        }
        
        $expanded = $pt . $num;
    }

    return $expanded;
}

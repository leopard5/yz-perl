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
		$portTypes[$count] =~ s/(\S+)?([A-Za-z]+) ?[0-9.\/]+/$1$2/;

        if($portTypes[$count] =~ /vlan/i)
        {
            $portNames[$count] =~ s/vlan/VLAN/;
            $portTypes[$count] =~ s/vlan/VLAN/;
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


		if ($config =~ /(\ninterface )/gc || $config =~ /(\n\n)/gc)
		{
			$out = $1;
			pos($config) = pos($config) - length($out);
			$interfaceEnd = pos($config);
			$interfaceConfig = substr($config, $interfaceStart, $interfaceEnd - $interfaceStart);

			# Determine if port is trunking
			if($interfaceConfig =~ /switchport (mode )?trunk/)
			{
				$portTypes[$count] .= "Trunk";
			}
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
			if($interfaceConfig =~ /no +shutdown/)
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


$test = 'no ft auto-sync startup-config

logging enable
logging trap 6
logging persistent 6
logging device-id context-name
logging host 192.168.137.11 udp/514 format emblem 
logging host 192.168.137.113 udp/514 



login timeout 0
hostname ace-tme-5
boot system image:c6ace-t1k9-mz.A2_1_2.bin
boot system image:c6ace-t1k9-mz.A2_1.bin

resource-class CART
  limit-resource all minimum 10.00 maximum unlimited
  limit-resource acl-memory minimum 10.00 maximum unlimited
  limit-resource buffer syslog minimum 10.00 maximum unlimited
  limit-resource conc-connections minimum 10.00 maximum unlimited
  limit-resource mgmt-connections minimum 10.00 maximum unlimited
  limit-resource proxy-connections minimum 10.00 maximum unlimited
  limit-resource rate bandwidth minimum 10.00 maximum unlimited
  limit-resource rate connection minimum 10.00 maximum unlimited
  limit-resource rate inspect-conn minimum 10.00 maximum unlimited
  limit-resource rate syslog minimum 10.00 maximum unlimited
  limit-resource regexp minimum 10.00 maximum unlimited
  limit-resource sticky minimum 10.00 maximum unlimited
  limit-resource xlates minimum 10.00 maximum unlimited
  limit-resource rate ssl-connections minimum 10.00 maximum unlimited
  limit-resource rate mgmt-traffic minimum 10.00 maximum unlimited
  limit-resource rate mac-miss minimum 10.00 maximum unlimited
resource-class for_radius
  limit-resource all minimum 10.00 maximum unlimited
  limit-resource sticky minimum 10.00 maximum unlimited
resource-class low_fat
  limit-resource all minimum 2.00 maximum unlimited
resource-class management
  limit-resource all minimum 2.00 maximum unlimited
resource-class my-stock-ticker-rc
  limit-resource all minimum 0.00 maximum unlimited
  limit-resource acl-memory minimum 0.00 maximum unlimited
  limit-resource buffer syslog minimum 0.00 maximum unlimited
  limit-resource conc-connections minimum 0.00 maximum unlimited
  limit-resource mgmt-connections minimum 0.00 maximum unlimited
  limit-resource proxy-connections minimum 0.00 maximum unlimited
  limit-resource rate bandwidth minimum 0.00 maximum unlimited
  limit-resource rate connection minimum 0.00 maximum unlimited
  limit-resource rate inspect-conn minimum 0.00 maximum unlimited
  limit-resource rate syslog minimum 0.00 maximum unlimited
  limit-resource regexp minimum 0.00 maximum unlimited
  limit-resource sticky minimum 20.00 maximum equal-to-min
  limit-resource xlates minimum 0.00 maximum unlimited
  limit-resource rate ssl-connections minimum 0.00 maximum unlimited
  limit-resource rate mgmt-traffic minimum 0.00 maximum unlimited
  limit-resource rate mac-miss minimum 0.00 maximum unlimited
resource-class website
  limit-resource all minimum 0.00 maximum unlimited
  limit-resource conc-connections minimum 5.00 maximum unlimited
  limit-resource sticky minimum 5.00 maximum unlimited


access-list acl line 10 extended permit ip any any 



class-map type management match-any C1
  description configured for bareblade
  2 match protocol ssh any
  3 match protocol icmp any
  4 match protocol telnet any
  5 match protocol http any
  6 match protocol https any
  7 match protocol snmp any

policy-map type management first-match P1
  class C1
    permit
timeout xlate 3600

interface vlan 30
  ip address 192.168.153.149 255.255.255.128
  access-group input acl
  access-group output acl
  service-policy input P1
  no shutdown

ip route 0.0.0.0 0.0.0.0 192.168.153.129

context ACS_Loadbalancer
  allocate-interface vlan 500
  member for_radius
context ctx-1-test
  allocate-interface vlan 30
  allocate-interface vlan 100
  allocate-interface vlan 200
  member for_radius
context ctx-2-test
  allocate-interface vlan 30
  allocate-interface vlan 100
  allocate-interface vlan 200
  member for_radius
context ctx-3-test
  allocate-interface vlan 30
  allocate-interface vlan 100-101
  member for_radius

snmp-server community cisco group Network-Monitor
snmp-server community private group Network-Monitor

snmp-server enable traps syslog 
  
username admin password 5 $1$rYB7xqNg$CzPFWMw6F1r5e0hP42WKc/  role Admin domain default-domain 
username www password 5 $1$UZIiwUk7$QMVYN1JASaycabrHkhGcS/  role Admin domain default-domain 
username ciscotme password 5 $1$lFIiFsZM$euU5XlaY5XMXAxq8xz/UR/  role Admin domain default-domain 
username cisco password 5 $1$s3ox0VNZ$0/mgIV1gOEP1bQaD4Xlh/1  role Network-Monitor domain default-domain 
ssh key rsa 1024 force

banner motd #  " NCM Test Module [temporary] contact:dmunoz "  #
';

foreach(GetPortInfo($test)) {
	print "$_\n";
}

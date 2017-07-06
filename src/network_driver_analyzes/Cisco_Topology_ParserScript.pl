#! /usr/local/bin/perl

# support
sub expandPortAbbr
{
	my ($abbr) = @_;
	
	my $expanded = $abbr;
	
	if ($abbr =~ /([a-zA-Z]+)([\d\/]+)/)
	{
		my $pt = $1;
		my $lowerpt = lc($pt);
		my $num = $2;
		
		if ($lowerpt eq "fa")
		{
			$pt = "FastEthernet";
		}
        elsif ($lowerpt eq "vlan")
        {
            $pt = "VLAN";
        }
		elsif ($lowerpt eq "gi")
		{
			$pt = "GigabitEthernet";
		}
		elsif ($lowerpt eq "po")
		{
			$pt = "Port-channel";
		}
		
		$expanded = $pt . $num;
	}
	
	return $expanded;
}

# interface
sub parseTopology_ShowInterfaces
{
	my ($rawdata) = @_;
	
	my @ports = ("startports");
	my @types = ("starttypes");
	my @data = ("startdata");
	my $currentIndex = 1;
	my %seen = ();

	# process showinterfaces
    #while ($rawdata =~ /(^|\n)([\S ]+?) is [\S ]*?(up|down), 
    #                    line protocol is (\S+).*\n[\S ]+?, 
    #                    address is ([\d\.a-f]+)([\S\s]+?)Last clearing of/gc)
    while($rawdata =~ /(^|\n)([\S ]+?) is [\S ]*?(up|down), line protocol is (\S+)/gc)
	{
		my $port = $2;
        my $portLink = $3;
        my $portProtocol = $4;
        my $start = pos($rawdata);
        my $end = -1;
        my $interfaceConfig = "";

        if($rawdata =~ /Last clearing/gc)
        {
            $end = pos($rawdata);
        }

        if($end != -1)
        {
                $interfaceConfig = substr($rawdata, $start, $end - $start);
        }
        else
        {
                $interfaceConfig = substr($rawdata, $start);
        }

		if ($port =~ /^Vlan/)
		{
			$port =~ s/Vlan/VLAN/;
		}

        if($portLink ne "" && $portProtocol ne "")
        {
                $ports[$currentIndex] = $port;
                $types[$currentIndex] = "port_state";
                if($portLink eq "down" || $portProtocol eq "down")
                {
                    $data[$currentIndex] = "Down";
                }
                else
                {
                    $data[$currentIndex] = "Up";
                }
                $currentIndex++;
        }

		if ($interfaceConfig =~ /(^|\n)\s+(Auto|Full|Half)-duplex(\s+\((Full|Half)\))? *, (.*)/)
		{
			my $duplex = lc($2);
			my $dup2 = lc($4);
			my $speed = $5;
			
			if ($duplex eq "auto" && $dup2 ne "")
			{
				$duplex = $dup2;
			}
		
			if ($duplex ne "auto")
			{
				$ports[$currentIndex] = $port;
				$types[$currentIndex] = "duplex_negotiated";
				$data[$currentIndex] = $duplex;
				$currentIndex++;
			}
			
			if ($speed ne "" && $port !~ /Gig/)
			{
				$speed =~ s/,.*//;
				if ($speed =~ /\(([\S ]+?)\)/)
				{
					$speed = $1;
				}

				if ($speed !~ /^[Aa]uto/ )
				{
					$speed =~ s/b\/s$//;
					$speed =~ s/M$//;
					
					$ports[$currentIndex] = $port;
					$types[$currentIndex] = "speed_negotiated";
					$data[$currentIndex] = $speed;
					$currentIndex++;
				}
			}
		}
		
        my $addr = "";
        if($interfaceConfig =~ /, address is ([\d\.a-f]+)/)
        {
            $addr = uc($1);
		    $addr =~ s/\.//g;

    		# Do not add a duplicate
    		if(defined $seen{$addr})
    		{
    			next;
    		}
    		else
    		{
    			$seen{$addr} = 1;
    		}
		    $ports[$currentIndex] = $port;
    		$types[$currentIndex] = "mac_internal";
    		$data[$currentIndex] = $addr;
    		$currentIndex++;
        
        }

	}
	
	$ports[$currentIndex] = "endports";
	$types[$currentIndex] = "endtypes";
	$data[$currentIndex] = "enddata";
	
	my @results = ();
	push @results, @ports;
	push @results, @types;
	push @results, @data;
	
	return @results;
}

sub parseTopology_Topology
{
	my ($rawdata) = @_;
	
	my @ports = ("startports");
	my @types = ("starttypes");
	my @data = ("startdata");
	my $currentIndex = 1;

	my %macports = ();
	# parse show mac-address-table (version 1), if it exists
	if ($rawdata =~ /^([\S\s]+?)\n +Mac Address Table\n\-+\n([\S\s]+?)$/)
	{
		$rawdata = $1;
		my $macaddrs = $2;
		$hasmacaddrs = 1;

		while ($macaddrs =~ /\n( +)?(\d+) +([\d\.a-f]+) +DYNAMIC +(\S+)/gic)
		{
			my $vlan = $2;
			my $port = expandPortAbbr($4);
			my $mac = uc($3);
			$mac =~ s/\.//g;

			$macports{$mac} = $currentIndex;
			
			$ports[$currentIndex] = $port;
			$types[$currentIndex] = "mac_connected";
			$data[$currentIndex] = $mac;
			$currentIndex++;
		}
	}
	elsif ($rawdata =~ /^([\S\s]+?)\nNon-static Address Table:\n([\S\s]+?)$/)
	{
		$rawdata = $1;
		my $macaddrs = $2;
		$hasmacaddrs = 1;
		
		while ($macaddrs =~ /\n([\d\.a-f]+) +Dynamic +(\d+) +(\S+)/gic)
		{
			my $mac = uc($1);
			my $vlan = $2;
			my $port = $3;
			$mac =~ s/\.//g;
			
			$macports{$mac} = $currentIndex;
			
			$ports[$currentIndex] = $port;
			$types[$currentIndex] = "mac_connected";
			$data[$currentIndex] = $mac;
			$currentIndex++;
		}
	}elsif ($rawdata =~ /^([\S\s]+?)\nLegend: \*.* primary entry([\S\s]+?)$/)
	{
		$rawdata = $1;
		my $macaddrs = $2;
		while($macaddrs =~ /\n ?\* +(\d+) + ([a-f0-9\.]+) +dynamic +\S+ +(\d+ +)?(\S+)/gc)
		{
			my $mac = uc($2);
			my $vlan = $1;
			my $port = expandPortAbbr($4);
			$mac =~ s/\.//g;

			# Don't add duplicates
			if($macports{$mac} eq "")
			{
				$macports{$mac} = $currentIndex;
				$ports[$currentIndex] = $port;
				$types[$currentIndex] = "mac_connected";
				$data[$currentIndex] = $mac;
				$currentIndex++;
			}
		}
	}elsif ($rawdata =~ /^([\S\s]+?)\nUnicast Entries([\S\s]+?)$/)
	{
		$rawdata = $1;
		my $macaddrs = $2;
		while($macaddrs =~ /\n *?(\S+) +([a-f0-9\.]+) +dynamic[ \S]+ +(\S+)/gc)
		{
			my $mac = uc($2);
			my $vlan = $1;
			my $port = expandPortAbbr($3);
			$mac =~ s/\.//g;

			# Don't add duplicates
			if($macports{$mac} eq "")
			{
				$macports{$mac} = $currentIndex;
				$ports[$currentIndex] = $port;
				$types[$currentIndex] = "mac_connected";
				$data[$currentIndex] = $mac;
				$currentIndex++;
			}
		}
	}elsif ($rawdata =~ /^([\S\s]+?)\nDestination Address  Address Type  VLAN  Destination Port\n[- ]+\n([\S\s]+)/)
	{
		# 0007.b35d.93d0 Self       1     Vlan1
		# 0004.002b.4f21 Dynamic       2     FastEthernet2/12
		# 0004.7595.f5e6 Dynamic       2     FastEthernet2/15

		$rawdata = $1;
		my $macaddrs = $2;
		while($macaddrs =~ /\n *([a-f0-9\.]+) +Dynamic +\d+ +(\S+)/gc)
		{
			my $mac = uc($1);
			my $port = expandPortAbbr($2);
			$mac =~ s/\.//g;

			# Don't add duplicates
			if($macports{$mac} eq "")
			{
				$macports{$mac} = $currentIndex;
				$ports[$currentIndex] = $port;
				$types[$currentIndex] = "mac_connected";
				$data[$currentIndex] = $mac;
				$currentIndex++;
			}
		}
	}
	##
	# Cisco IOS-XR has location specific arp information
	#Address         Age        Hardware Addr   State      Type  Interface
	#204.95.99.142   -          0015.63bc.3981  Interface  ARPA  GigabitEthernet0/7/0/0
	#204.95.99.141   00:22:26   0015.2c19.f800  Dynamic    ARPA  GigabitEthernet0/7/0/0	
	elsif ( $rawdata =~ /Address\s+Age\s+Hardware\s+Addr\s+State\s+Type\s+Interface/){
		while ($rawdata =~ / +([\d\.]+) +([\d:]+) +([\da-f\.]+) +(\S+) +(\S+) +(\S+)/gc){
			my $ip = $1;
			my $age = $2;
			my $mac = $3;
			my $type = $4;
			my $port = $6;
			
			$ports[$currentIndex] = $port;
			$types[$currentIndex] = "$type";
			$data[$currentIndex] = "$mac|$ip";
			$currentIndex++;
			$ports[$currentIndex] = "endports";
			$types[$currentIndex] = "endtypes";
			$data[$currentIndex] = "enddata";
			
			my @results = ();
			push @results, @ports;
			push @results, @types;
			push @results, @data;
			
			return @results;
		}
	}
	
	# now parse show arp
	while ($rawdata =~ /\nInternet +([\d\.]+) +([\d\-]+) +([\da-f\.]+) +\S+ +(\S+)/gc)
	{
		my $ip = $1;
		my $age = $2;
		my $mac = uc($3);
		my $port = $4;
        if($port =~ /Vlan/)
        {
            $port = uc($port);
        }
		$mac =~ s/\.//g;
		
		if ($age eq "-") { next; }
		
		my $addentry = 1;
		
		if ($hasmacaddrs == 1 && $port =~ /^Vlan/i) 
		{
			# see if this mac address is associated with a port already stored
			$portIndex = $macports{$mac};
			if ($portIndex > 0)
			{
				if ($types[$portIndex] ne "macip_connected")
				{
					# change this to a combined connected type
					$types[$portIndex] = "macip_connected";
					$data[$portIndex] .= "|$ip";
					$addentry = 0;  # the mac is already there so don't add it again
				}
				else
				{
					# just add this as a stray ip address for now
					$ports[$currentIndex] = $ports[$portIndex];
					$types[$currentIndex] = "ip_connected";
					$data[$currentIndex] = $ip;
					$currentIndex++;
					$addentry = 0;
				}
			}
		}

		if ($addentry == 1)
		{ # add as mac_ip entry
			$ports[$currentIndex] = $port;
			$types[$currentIndex] = "macip_connected";
			$data[$currentIndex] = "$mac|$ip";
			$currentIndex++;
		}
	}
	
	$ports[$currentIndex] = "endports";
	$types[$currentIndex] = "endtypes";
	$data[$currentIndex] = "enddata";
	
	my @results = ();
	push @results, @ports;
	push @results, @types;
	push @results, @data;
	
	return @results;
}

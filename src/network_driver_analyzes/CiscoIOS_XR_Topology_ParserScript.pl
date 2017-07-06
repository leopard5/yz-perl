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
	while ($rawdata =~ /(^|\n)(?!Null\d+)([\S ]+) is [\S ]*?(up|down), line protocol.*[\n\S ]+?, address is ([\d\.a-f]+)([\n\S\s]+?)Last clearing of/gc)
	{
		my $port = $2;
		my $addr = uc($4);
		my $rest = $5;
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
		if ($port =~ /^Vlan/)
		{
			$port =~ s/Vlan/VLAN/;
		}
		$ports[$currentIndex] = $port;
		$types[$currentIndex] = "mac_internal";
		$data[$currentIndex] = $addr;
		$currentIndex++;

		if ($rest =~ /(^|\n)\s+(Auto|Full|Half)-duplex(\s+\((Full|Half)\))? *, (.*)/)
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

		while ($macaddrs =~ /\n +(\d+) +([\d\.a-f]+) +DYNAMIC +(\S+)/gic)
		{
			my $vlan = $1;
			my $port = expandPortAbbr($3);
			my $mac = uc($2);
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
		while($macaddrs =~ /\n ?\* +(\d+) + ([a-f0-9\.]+) +dynamic +\S+ +\d+ +(\S+)/gc)
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
	# 
	# -------------------------------------------------------------------------------
	# 0/RP0/CPU0
	# -------------------------------------------------------------------------------
	# Address         Age        Hardware Addr   State      Type  Interface
	# 172.25.97.148   03:23:04   0019.e86f.52c0  Dynamic    ARPA  MgmtEth0/RP0/CPU0/0
	# 172.25.97.37    -          001a.6c40.d4ca  Interface  ARPA  MgmtEth0/RP0/CPU0/0
	# 172.25.97.32    00:09:11   0004.4dc5.4a0c  Dynamic    ARPA  MgmtEth0/RP0/CPU0/0
	# 172.25.97.40    03:24:54   001a.e29a.4910  Dynamic    ARPA  MgmtEth0/RP0/CPU0/0
	# 172.25.97.31    03:50:09   000b.be66.1a81  Dynamic    ARPA  MgmtEth0/RP0/CPU0/0
	# 172.25.97.5     03:51:42   0006.28d6.9381  Dynamic    ARPA  MgmtEth0/RP0/CPU0/0
	# 172.25.97.1     00:00:00   0012.8048.2400  Dynamic    ARPA  MgmtEth0/RP0/CPU0/0
	#
	while ($rawdata =~ /\n([\d\.]+) +([\d:])+ +([\da-f\.]+) +\S+ +ARPA +(\S+)/gc)
	{
		my $ip = $1;
		my $age = $2;
		my $mac = uc($3);
		my $port = $4;

		$mac =~ s/\.//g;
		
		if ($age eq "-") { next; }
		
		$ports[$currentIndex] = $port;
		$types[$currentIndex] = "macip_connected";
		$data[$currentIndex] = "$mac|$ip";
		$currentIndex++;
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

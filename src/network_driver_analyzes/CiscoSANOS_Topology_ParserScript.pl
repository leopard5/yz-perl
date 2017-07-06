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
	while ($rawdata =~ /^([\S ]+?) is [\S ]*?(up|down).*\n[\S ]+is (.*)\s+Address is (.*)([\S\s]+?)\n\s*\n/mgc)
	{
		my $port = $1;
		my $addr = uc($4);
		my $rest = $5;
		$addr =~ s/\.//g;

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


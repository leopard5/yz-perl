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

sub parseTopology_Topology
{
	my ($rawdata) = @_;
	
	my @ports = ("startports");
	my @types = ("starttypes");
	my @data = ("startdata");
	my $currentIndex = 1;

	my %macports = ();
	
	#10.255.41.1     00.0e.38.24.59.3f  vlan10    GATEWAY    10     30 sec       up 
	while ($rawdata =~ /\n([\d\.]+) +([\da-f\.]+) +(\S+)/gc)
	{
		my $ip = $1;
		my $mac = uc($2);
		my $port = uc($3);
		$mac =~ s/\.//g;
		$port =~ s/([A-Z]+)(\d+)/$1 $2/;
		
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

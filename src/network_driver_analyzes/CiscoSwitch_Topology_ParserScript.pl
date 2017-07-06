#! /usr/local/bin/perl

# interface
sub parseTopology_ShowInterfaces
{
	my ($rawdata) = @_;
	
	my @ports = ("startports");
	my @types = ("starttypes");
	my @data = ("startdata");
	my $currentIndex = 1;

	# process showinterfaces
	while ($rawdata =~ /(^|\n)([\S ]+?) is (Enabled|Suspended|Disabled).*\n.*\nAddress is ([\d\.A-F]+)/gc)
	{
		my $port = $2;
		my $pstatus = "Down";
		if ($3 eq "Enabled") 
		{
			$pstatus = "Up";	
		}
		my $addr = uc($4);
		$addr =~ s/\.//g;
		
		$ports[$currentIndex] = $port;
		$types[$currentIndex] = "mac_internal";
		$data[$currentIndex] = $addr;
		$currentIndex++;
		
		$ports[$currentIndex] = $port;
		$types[$currentIndex] = "port_state";
		$data[$currentIndex] = $pstatus;
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

sub parseTopology_Topology
{
	my ($rawdata) = @_;
	
	my @ports = ("startports");
	my @types = ("starttypes");
	my @data = ("startdata");
	my $currentIndex = 1;

	# parse show mac-address-table (version 1), if it exists
	while ($rawdata =~ /\n+([\.\dA-F]+) +(\S+ \S+) +Dynamic +\S+/gic)
	{
		my $mac = $1;
		my $port = $2;
		$mac =~ s/\.//g;

		$macports{$mac} = $currentIndex;
			
		$ports[$currentIndex] = $port;
		$types[$currentIndex] = "mac_connected";
		$data[$currentIndex] = $mac;
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

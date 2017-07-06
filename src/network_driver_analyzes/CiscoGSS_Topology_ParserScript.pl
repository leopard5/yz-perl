#! /usr/local/bin/perl

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
	while ($rawdata =~ /\n(\S+)\s+Link encap\:Ethernet\s+HWaddr (\S+)/gc)
	{
		my $port = $1;
		my $mac  = uc($2);

		# BasicIP uses long form of the name
		$port =~ s/eth/ethernet /;
		$mac  =~ s/://g;

		# Extract MAC addresses for our ports
		$ports[$currentIndex] = $port;
		$types[$currentIndex] = "mac_internal";
		$data[$currentIndex] = $addr;
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
	
	# now parse show arp
	while ($rawdata =~ /\n(\d+\.\d+\.\d+\.\d+)\s+ether\s+([0-9A-F:]+)\s+\S+\s+(\S+)/gc)
	{
		my $ip   = $1;
		my $mac  = uc($2);
		my $port = $3;

		# BasicIP uses the short version
		$port =~ s/eth/ethernet /;
		$mac  =~ s/\://g;
		
		# change this to a combined connected type
		$types[$currentIndex] = "macip_connected";
		$data [$currentIndex] = "$mac|$ip";
		$ports[$currentIndex] = $port;
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

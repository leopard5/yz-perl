#! /usr/local/bin/perl

#CISCO507-CE-1#show arp
#Protocol  Address          Flags      Hardware Addr     Type  Interface
#Internet  10.255.100.1     Adj        00:01:42:26:18:FF ARPA  FastEthernet0/0

sub parseTopology_Topology
{
	my ($rawdata) = @_;
	
	my @ports = ("startports");
	my @types = ("starttypes");
	my @data = ("startdata");
	my $currentIndex = 1;
	
	# parse show mac-address-table, if it exist
	while ($rawdata =~ /Internet\s+(\d+\.\d+\.\d+\.\d+)\s+\S+\s+([\dA-F:]+)\s+\S+\s+(\S+)/gc)
	{
		$ip   = $1;
		$mac  = uc($2);
		$port = $3;
		$mac  =~ s/://g;

		# For some reason the device returns "FastEthernet0/0" for the port, when
		# "FastEthernet 0/0" is returned by BasicIP... do a fudge to make it work
		# [_should_ work for other interface names]
		$port =~ s/([A-Za-z]+)/"$1 "/e;

		$ports[$currentIndex] = $port;
		$types[$currentIndex] = "mac_connected";
		$data [$currentIndex] = $mac;
		$currentIndex++;

		# always add ip
		$ports[$currentIndex] = $port;
		$types[$currentIndex] = "ip_connected";
		$data [$currentIndex] = $ip;
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

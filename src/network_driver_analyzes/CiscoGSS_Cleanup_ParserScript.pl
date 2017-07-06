#! /usr/local/bin/perl

sub stripCarriageReturns
{
	my($rawdata) = @_;

	$rawdata =~ s/[\r\x80\xC0]//g;

	return $rawdata;
}

sub removeMores
{
	my($rawdata) = @_;

	$rawdata = stripCarriageReturns($rawdata);
	$rawdata =~ s/\x1b\[7m--More--\x1b\[m//g;
	$rawdata =~ s/\x1b\[K//g;

	# Fix wrapped lines - terminal is known to be 80 chars wide
	$rawdata =~ s/(\n.{80})\n/$1/ge;
	return $rawdata;
}

sub stripLastLine
{
	my($rawdata) = @_;
	$rawdata =~ s/\n[\S ]+\n*$//;

	return $rawdata;
}

sub cleanupConfiguration
{
	my($config,$binary) = @_;
	my(@array) = ();

	$config = removeMores( $config );
	
	# Remove header lines [running config and startup config (inserts an extra line)]
	$config =~ s/^show running-config\n//;
	$config =~ s/^show startup-config\n\nGSS configuration.*\n\n//;

	$cleanConfig = stripLastLine($config);
	return $cleanConfig;
}

sub cleanupTech
{
	my($config) = @_;
	my(@array) = ();

	$config =  removeMores( $config );
	$config =~ s/^show tech-support config\n//;
	$config =  stripLastLine($config);
	
	return $config;
}

sub cleanupVersion
{
	my($rawdata) = @_;

	$cleandata = removeMores($rawdata);
	$cleandata =~ s/show version\n//;
	$cleandata = stripLastLine($cleandata);

	return $cleandata;
}

sub cleanupRouting
{
	my($rawdata) = @_;

	$cleandata = removeMores($rawdata);
	if ($cleandata =~ /show ip route\s+([\S\s+]+)/) {
		$cleandata = $1;
	}
	$cleandata = stripLastLine($cleandata);

	return $cleandata;
}

sub cleanupInterfaces
{
	my($rawdata) = @_;
	
	$cleandata = removeMores($rawdata);
	$cleandata =~ s/.*show interface.*\n//g;
	$cleandata = stripLastLine($cleandata);

	return $cleandata;
}

sub cleanupFileSystem
{
	my($rawdata) = @_;

	$cleandata = removeMores($rawdata);
	$cleandata =~ s/show disk\n//g;
	$cleandata = stripLastLine($cleandata);

	return $cleandata;
}

sub cleanupTopology
{
	my ($rawdata) = @_;
	
	$rawdata = removeMores($rawdata);
	
	# process
	$rawdata =~ s/(^|\n)show arp\n//;
	$rawdata =~ s/\n[\S ]+?show mac-address-table\n/\n\n/;
	
	# strip away any errors indicating lack of support
	$rawdata =~ s/\n +\^\n//;
	$rawdata =~ s/\n\% Invalid input detected at .*//;		
	$rawdata = stripLastLine($rawdata) . "\n";
	
	return $rawdata;
}

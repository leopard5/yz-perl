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
	$rawdata =~ s/\n--- More ---\n\n//g;
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
	my($config) = @_;

	$cleanConfig =  removeMores($config);
	$cleanConfig =~ s/show running-config\n//;
	$cleanConfig =~ s/Building configuration...\n//;
	$cleanConfig =~ s/Current configuration:\n//;
	$cleanConfig =  stripLastLine($cleanConfig);

	return $cleanConfig;
}

sub cleanupVersion
{
	my($rawdata) = @_;

	$cleandata =  removeMores($rawdata);
	$cleandata =~ s/show version\n//;
	$cleandata =  stripLastLine($cleandata);

	return $cleandata;
}

sub cleanupInterfaces
{
	my($rawdata) = @_;

	$cleandata =  removeMores($rawdata);
	$cleandata =~ s/show interfaces\n//;
	$cleandata =  stripLastLine($cleandata);

	return $cleandata;
}

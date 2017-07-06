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
	$rawdata =~ s/\n\n--More--[ \S]*\n/\n/g;

	return $rawdata;
}

sub stripLastLine
{
	my($rawdata) = @_;

	@lines = split('\n', $rawdata);

	$#lines--;

	my($cleandata) = "";
	my($linecount) = 0;
	foreach $line (@lines)
	{
		if ($linecount == $#lines)
		{
			$cleandata .= "$line";
		}
		else
		{
			$cleandata .= "$line\n";
		}
		$linecount++;
	}

	while ($cleandata =~ /\n$/)
	{
		$cleandata =~ s/\n$//g;
	}

	return $cleandata;
}

sub cleanupConfiguration
{
	my($config) = @_;
	my(@array) = ();

	$start = index($config, "!");
	if ($start == -1)
	{
		$start = 0;
	}

	$stop = -1;
	$pos = -1;
	while (($pos = index($config, "end", $pos)) > -1)
	{
		$stop = $pos;
		$pos++;
	}

	if ($stop > -1)
	{
		$cleanConfig = substr($config, $start, $stop-$start+3);
	}
	else
	{
		$cleanConfig = substr($config, $start);
	}

	$cleanConfig = removeMores($cleanConfig);

	# append a newline to match up with file transfer results
	$cleanConfig .= "\n";

	# and make sure any ^C sequences wrapping banners are converted
	# to ASCII 3 (\cC) characters

	# using a loop since the global tag doesn't work for this
	while ($cleanConfig =~ s/\nbanner([\S ]+?)\^C(.*?)\^C\n(\!|(banner))/\nbanner$1\cC$2\cC\n$3/s)
	{
		# do nothing
	}

	return $cleanConfig;
}

sub cleanupTFTPConfiguration
{
	my($config) = @_;

	$start = index($config, "!");
	if ($start == -1)
	{
		$start = 0;
	}

	return substr($config, $start);
}

sub cleanupVersion
{
	my($rawdata) = @_;

	$start = index($rawdata, "Cisco");
	$cleandata = substr($rawdata, $start);
	$cleandata = removeMores($cleandata);

	$cleandata = stripLastLine($cleandata);

	return $cleandata;
}

sub cleanupInterfaces
{
	my($rawdata) = @_;

	$cleandata = removeMores($rawdata);

	$cleandata =~ s/show interfaces\n+//;
	$cleandata =~ s/[\S]+show vlan\n+/\n\n/;
	$cleandata = stripLastLine($cleandata);

	return $cleandata;
}


sub cleanupModule
{
	my($rawdata) = @_;

	$start = index($rawdata, "Slot");
	$cleandata = substr($rawdata, $start);
	$cleandata = removeMores($rawdata);

	return $cleandata;
}

sub cleanupTopology
{
	my($rawdata) = @_;

	$cleandata = removeMores($rawdata);

	$cleandata =~ s/show mac-address-table\n+//;
	$cleandata = stripLastLine($cleandata);

	return $cleandata;
}


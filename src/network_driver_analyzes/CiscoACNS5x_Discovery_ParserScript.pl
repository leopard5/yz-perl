#! /usr/local/bin/perl

#retrieval scripts
sub loadIsACNS5x
{
	my ($versioninfo) = @_;
	if ($versioninfo =~ /Application and Content Networking System Software \(ACNS\)/g)
	{
		return $versioninfo;
	}
	else
	{
		return "Version info does not match.";
	}
}

# testing scripts

sub testIsACNS5x
{
	my ($val) = @_;

	if ($val =~ /ce7326-5.3.3/) {
		# Fail out and let the old driver take this
		return "This driver does not support the WEA3286 device.";
	}

	if ($val =~ /Software Release (\d+)\.(\d+\.\d+)/g)
	{
		$major = $1;
		$minor = $2;
		
		if ($major eq "5")
		{
			return "0";
		}
	}
	
	return "Could not find \"Software Release 5.x\" in version information.";
}

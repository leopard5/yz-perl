#! /usr/local/bin/perl

# retreival scripts
sub loadIsACNS
{
	my ($versioninfo) = @_;

	if ($versioninfo =~ /(Application and Content Networking System Software \(ACNS\))/g)
	{
		return $versioninfo;
	}
	else
	{
		return "Version info does not match.";
	}
}

# testing scripts

sub testIsACNS
{
	my ($val) = @_;
	if ($val =~ /Application and Content Networking System Software \(ACNS\)/g)
	{
		# Now this driver _only_ supports the WAE7326 running ACNS version 5.3.3

		if ($val =~ /ce7326-5.3.3/g)
		{
			return "0";
		}
	}
	
	return "Could not find \"ce7326-5.3.3\" in version information.";
}

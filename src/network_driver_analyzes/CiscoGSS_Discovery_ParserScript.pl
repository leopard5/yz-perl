#! /usr/local/bin/perl

# retreival scripts
sub GetIsGSS
{
	my ($versioninfo) = @_;
	
	if ($versioninfo =~ /Global Site Selector \(GSS\)/)
	{
		return $versioninfo;
	}
	else
	{
		return "Version info does not match.";
	}
}

# testing scripts
sub testIsGSS
{
	my ($val) = @_;
	
	if ($val =~ /GSS-(4490|4491|4492)/)
	{
		return "0";
	}
	
	return "Could not find \"GSS-(4490|4491|4492)\" in version information.";
}

sub compareGE
{
	my $val1 = shift;
	my $val2 = shift;
	
	unless ($val1 >= $val2) 
	{ 
		return "no $val1 < $val2";
	}
	
	return 0;
}

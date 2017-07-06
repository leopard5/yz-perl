#! /usr/local/bin/perl

# retreival scripts
sub GetIsFastHub
{
	my ($versioninfo) = @_;
	
	if ($versioninfo =~ /(Cisco FastHub)/)
	{
		return $versioninfo;
	}
	else
	{
		return "Version info does not match.";
	}
}

# testing scripts
sub testIsFastHub
{
	my ($val) = @_;
	
	if ($val =~ /FastHub (400)/)
	{
		return "0";
	}
	
	return "Could not find \"Cisco FastHub\" in version information.";
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

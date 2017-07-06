#! /usr/local/bin/perl

# retreival scripts
sub loadIsCiscoACE
{
	my ($versioninfo) = @_;
	
	if ($versioninfo =~ /Cisco Application Control Software[\n\S\s ]+?system: +Version ([\S\s]+)/)
	{

		if ($versioninfo =~ /\S+\/(\S+)(>|#)/)
		{
			return $1;
		} else {
			return "Version info does not match.";
		}
	}
	else
	{
		return "Version info does not match.";
	}
}

# testing scripts

sub testIsCiscoACE
{
	my ($val) = @_;

	if ($val =~ /Admin/)
	{
		return "0";
	}
	
	return "Could not find \"Admin\" in version information.";
}

sub testIsCiscoACEContext
{
	my ($val) = @_;

	if (($val ne "Version info does not match.") && ($val !~ /Admin/))
	{
		return "0";
	}

	return "Could not find context information.";
}

# helper functions

sub testModelInSet
{
	my $actual_model = shift;
	my $expected_models = shift;
	
	# split up expected_sysoid with | characters
	foreach $model (split /\|/,$expected_models) 
	{
		if ($actual_model eq $model) 
		{ 
			return 0; 
		}
	}

	if($actual_model && $actual_model =~ /^\S+$/)
    {
        return "model $actual_model != $expected_models";
    }
    else
    {
        return "Could not determine model number to match against '$expected_models'";
    }

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

sub compareLT
{
	my $val1 = shift;
	my $val2 = shift;
	
	unless ($val1 < $val2) 
	{ 
		return "no $val1 < $val2"; 
	}
	
	return 0;
}

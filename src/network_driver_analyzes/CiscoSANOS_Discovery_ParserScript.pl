#! /usr/local/bin/perl

# retreival scripts
sub loadIsCiscoSAN
{
	my ($versioninfo) = @_;
	
	if ($versioninfo =~ /Cisco Storage Area Networking Operating System[\n\S\s ]+?system: +version (\S+)/)
	{
		return $1;
	}
	else
	{
		return "Version info does not match.";
	}
}

# testing scripts

sub testIsCiscoSAN
{
	my ($val) = @_;
	

	if ($val =~ /(2\.0|2\.1|3\.0|3\.1|3\.2|3\.3)/)
	{
		return "0";
	}
	
	return "Could not find \"2.0\" or \"2.1\" or \"3.0\" or \"3.1\" or \"3.2\" or \"3.3\" in version information.";
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

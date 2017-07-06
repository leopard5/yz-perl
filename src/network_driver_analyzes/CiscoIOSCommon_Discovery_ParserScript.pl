#! /usr/local/bin/perl

# retreival scripts
sub GetIsIOS
{
	my ($versioninfo) = @_;
	
	if ($versioninfo =~ /(IOS \(tm\)[ \S]+\s+Software|Cisco IOS( XR)? Software.*Version \S+)/)
	{
		return $1;
	}
	else
	{
		return "Version info does not match.";
	}
}

sub GetDeviceModel
{
	my ($versioninfo) = @_;
	
	if ($versioninfo =~ /IOS \(tm\)\s+([\S ]+)\s+Software/ || 
	    $versioninfo =~ /Cisco IOS Software, (\S+) Software/ ||
		$versioninfo =~ /Cisco IOS Software, Catalyst (\S+) L3 Switch Software/ ||
		$versioninfo =~ /Cisco IOS (XR) Software/ )
	{
		return $1;
	}
	else
	{
		return "Version info does not match.";
	}
}

sub GetCatalystModel
{
	my ($versioninfo) = @_;
	
	if ($versioninfo =~ /cisco Catalyst (\d+) \([\S]+\) processor/)
	{
		return $1;
	}
	else
	{
		return "Version info does not match.";
	}
}

sub GetIOSVersion
{
	my ($versioninfo) = @_;
	my (@array)=("","","");

	return(@array) if $versioninfo =~ /IOS XR/;
	
	if ($versioninfo =~ /IOS[\s\S]+?Version (\d+)\.(\d+)(\((\S+)\))?/)
	{
		$array[0] = $1;
		$array[1] = $2;
		$array[2] = $3;
	}

	return @array;
}

sub GetIOSXR
{
	my ($versioninfo) = @_;

	if ($versioninfo =~ /(IOS XR)/)
	{
		return $1;
	}
	else
	{
		return "IOS XR not found";
	}
}

sub GetIsION
{
	my ($versioninfo) =@_;


	if ($versioninfo =~ /(IOS[\s\S]+?\(\S+?-VM\)), Version/)
	{
		return $1;
	}
	else
	{
		return "Version info does not match";
	}
}

sub GetIsCBS
{
	my ($versioninfo) =@_;


	if ($versioninfo =~ /(CBS30X0)/)
	{
		return $1;
	}
	else
	{
		return "Version info does not match";
	}
}

sub GetVersion
{
	my ($versioninfo) = @_;
	my (@array)=("","","");

	if ($versioninfo =~ /Cisco (Systems )*Catalyst \d+/) 
	{
		if($versioninfo =~ /Version +V(\d+)\.(\d+)\.(\d+) +/ || $versioninfo =~ /Cisco Systems Catalyst [\S]+,V(\d+)\.(\d+)\.(\d+)/)
		{
			$array[0] = $1;
			$array[1] = $2;
			$array[2] = $3;
		}
	}

	return @array;
}

# testing scripts
sub testIsIOS
{
	my ($val) = @_;
	

	if ($val =~ /(IOS \(tm\)[ \S]+\s+Software|Cisco IOS( XR)? Software.*Version \S+)/)
	{
		return "0";
	}
	
	return "Could not find \"IOS \(tm\) * Software\" in version information.";
}

sub testIsION
{
	my ($val) = @_;

	if ($val =~ /\(\S+?-VM\)/)
	{
		return "0";
	}

	return "Could not detect IOS modularity.";
}

sub testIsXR
{
	my ($val) = @_;

	if ($val =~ /IOS XR/)
	{
		return "0";
	}

	return "Cound not find IOS XR.";
}

sub testIsCBS
{
	my ($val) = @_;

	if ($val =~ /(CBS30X0)/)
	{
		return "0";
	}

	return "Could not find \"CBS30X0\" in version information.";
}

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

#! /usr/local/bin/perl

# retrieval scripts

sub GetSysOID
{
	my ($config) = @_;
	my (@array)=("");

	if ($config =~ /=(1.3.6.1.(\d+\.)+\d+)/)
	{ 
		$array[0]=$1; 
	}
	else
	{ 
		$array[0]="unknown"; 
	}
	
	return @array;
}

sub GetSysDescr
{
	my ($config) = @_;
	my (@array)=("");

	if (length($config) > 0)
	{ 
		$array[0]=$config; 
	}
	else
	{ 
		$array[0]="unknown"; 
	}
	
	return @array;
}

# testing scripts

sub testSysOIDInSet
{
	my $actual_sysoid = shift;
	my $expected_sysoid = shift;
	
	# split up expected_sysoid with | characters
	foreach $oid (split /\|/,$expected_sysoid) 
	{
		if ($actual_sysoid eq $oid) 
		{ 
			return 0; 
		}
	}

	if($actual_sysoid && $actual_sysoid =~ /^\S+$/)
    {
        return "System OID $actual_sysoid != $expected_sysoid";
    }
    else
    {
        return "Could not determine model number to match against '$expected_sysoid'";
    }
}

sub testSysOIDPartiallyInSet
{
	my ($actual_sysoid, $expected_sysoid, $excluded_sysoid) = @_;

	my %exclude = ();
	foreach $oid (split /\|/,$excluded_sysoid) 
	{
		$exclude{$oid} = 1;
	}

	if($exclude{$actual_sysoid} == 1) # Ignore FWSM
	{
		return "Appears to be a non IOS device (or a device excluded from discovering under this method).";
	}

	# split up expected_sysoid with | characters
	foreach $oid (split /\|/,$expected_sysoid) 
	{
		if ($actual_sysoid =~ /$oid/)
		{ 
			return 0; 
		}
	}

	if($actual_sysoid && $actual_sysoid =~ /^\S+$/)
    {
        return "System OID $actual_sysoid != $expected_sysoid";
    }
    else
    {
        return "SysOID does not appeat to match '$expected_sysoid'";
    }
}


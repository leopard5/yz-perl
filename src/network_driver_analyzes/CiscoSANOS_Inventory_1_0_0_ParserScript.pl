#! /usr/local/bin/perl

sub GetInventoryInfo
{
	my($config) = @_;
	my(@array) = ();
	my($count) = 0;

	#Parsing Modules
	while ($config =~ /(Module in slot (\d+) is ok[\S\s\n ]+?)\n\n/gc)
	{
		$modconfig = $1;
		$module = "Module $2";

		if ($modconfig =~ /Module type is \"(.*)\"/) {
			$desc = $1;
			$array[$count] = "Description";
			$array[$count+1] = $module;
			$array[$count+2] = $desc;
			$count+=3;
		}
		
		if ($modconfig =~ /Model number is (.*)/) {
			$mdel = $1;
			$array[$count] = "Model";
			$array[$count+1] = $module;
			$array[$count+2] = $mdel;
			$count+=3;
		}

		if ($modconfig =~ /Serial number is (\S+)/)
		{
			$sn = $1;
			$array[$count] = "SerialNumber";
			$array[$count+1] = $module;
			$array[$count+2] = $sn;
			$count+=3;
		}

		if ($modconfig =~ /H\/W version is (\S+)/)
		{
			$hw = $1;
			$array[$count] = "HardwareVer";
			$array[$count+1] = $module;
			$array[$count+2] = $hw;
			$count+=3;
		}
	}
	
	#Parsing POWER SUPPLIES
	while ($config =~ /(PS in slot (\S+) is ok[\S\s\n ]+?)\n\n/gc)
	{
		$modconfig = $1;
		$module = "PS $2";

		if ($modconfig =~ /Power supply type is \"(.*)\"/) {
			$desc = $1;
			$array[$count] = "Description";
			$array[$count+1] = $module;
			$array[$count+2] = $desc;
			$count+=3;
		}
		
		if ($modconfig =~ /Model number is (.*)/) {
			$mdel = $1;
			$array[$count] = "Model";
			$array[$count+1] = $module;
			$array[$count+2] = $mdel;
			$count+=3;
		}

		if ($modconfig =~ /Serial number is (\S+)/)
		{
			$sn = $1;
			$array[$count] = "SerialNumber";
			$array[$count+1] = $module;
			$array[$count+2] = $sn;
			$count+=3;
		}

		if ($modconfig =~ /H\/W version is (\S+)/)
		{
			$hw = $1;
			$array[$count] = "HardwareVer";
			$array[$count+1] = $module;
			$array[$count+2] = $hw;
			$count+=3;
		}
	}
	
	#Parsing MDS chsssis
	if ($config =~ /(MDS Switch is booted up[\S\s\n ]+?)\n\n/)
	{
		$modconfig = $1;
		$module = "MDS";

		if ($modconfig =~ /Switch type is \"(.*)\"/) {
			$desc = $1;
			$array[$count] = "Description";
			$array[$count+1] = $module;
			$array[$count+2] = $desc;
			$count+=3;
		}
		
		if ($modconfig =~ /Model number is (.*)/) {
			$mdel = $1;
			$array[$count] = "Model";
			$array[$count+1] = $module;
			$array[$count+2] = $mdel;
			$count+=3;
		}

		if ($modconfig =~ /Serial number is (\S+)/)
		{
			$sn = $1;
			$array[$count] = "SerialNumber";
			$array[$count+1] = $module;
			$array[$count+2] = $sn;
			$count+=3;
		}

		if ($modconfig =~ /H\/W version is (\S+)/)
		{
			$hw = $1;
			$array[$count] = "HardwareVer";
			$array[$count+1] = $module;
			$array[$count+2] = $hw;
			$count+=3;
		}
	}

	return @array;
}

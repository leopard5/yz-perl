#! /usr/local/bin/perl

sub GetDeviceInfoTypesAndValues
{
	my($config,$version,$deviceType, $customSerialNumber) = @_;
	my(@array) = ();

	# first supply slots for fast lookup data
	$array[0] = ""; # model
	$array[1] = $deviceType; # devtype
	$array[2] = ""; # devname
	$array[3] = ""; # contact
	$array[4] = ""; # osver
	$array[5] = ""; # location
	$array[6] = ""; # serial
	$array[7] = ""; # systemmemory
	$array[8] = ""; # romver
	$array[9] = ""; # processor

	# supply hardcoded
	$index = 10;
	$array[$index] = "Manufacturer";
	$array[$index+1] = "Cisco";
	$index += 2;

	if ($version =~ /Model number: (\S+)/i)
	{
		$array[$index] = "Model";
		$array[$index+1] = $1;
		$array[0] = $array[$index+1]; # populate fast lookup
		$index += 2;
	}
	elsif ($version =~ /cisco ([\S ]+?) *\([\S ]+\) processor/i ||
           $version =~ /Cisco ([\S\d]+) .*\(revision \S+\) with/ )
	{
		$array[$index] = "Model";
		$array[$index+1] = $1;
		$array[0] = $array[$index+1]; # populate fast lookup
		$index += 2;
	}elsif ($version =~ /IOS \(tm\)\s+([\S ]+)\s+Software/ || 
		    $version =~ /Cisco IOS Software, (\S+) Software/ ||
			$version =~ /Cisco IOS Software, Catalyst (\S+) L3 Switch Software/
			){
		$array[$index] = "Model";
		$array[$index+1] = $1;
		$array[0] = $array[$index+1]; # populate fast lookup
		$index += 2;
	} elsif ($version =~ /Model number is (\S+)/){
		$array[$index] = "Model";
		$array[$index+1] = $1;
		$array[0] = $array[$index+1];
		$index += 2;
       } elsif ($version =~ /Product Number: +(\S+)/)
       {
               $array[$index] = "Model";
               $array[$index+1] = $1;
               $array[0] = $array[$index+1];
               $index += 2;
	}

	if($version =~ /(BOOTFLASH): .*Version ([\S ]+),/ ||
	   $version =~ /(BOOTFLASH|BOOTLDR|ROM): .*Version ([\S ]+),/ ||
	   $version =~ /(ROM): Bootstrap program is ([\S ]+)/ ||
	   $version =~ /(ROM): (\S+)/ )
	{
		$array[$index] = "ROMVer";
		$array[$index+1] = $2;
		$array[8] = $array[$index+1]; # populate fast lookup
		$index += 2;
	}

    if($customSerialNumber =~ /true/i)
    {
        if($config =~ /snmp-server chassis-id (\S+)/)
        {
    		$array[$index] = "SerialNumber";
    		$array[$index+1] = $1;
    		$array[6] = $1; # populate fast lookup
    		$index += 2;
        }
    }
    else
    {
		if ($version =~ /Serial number is (\S+)/)
		{
	    		$array[$index] = "SerialNumber";
	    		$array[$index+1] = $1;
	    		$array[6] = $1; # populate fast lookup
	    		$index += 2;
		}	
    }

	if ($config =~ /switchname[\s ](\S+)/)
	{
		$array[$index] = "Hostname";
		$array[$index+1] = $1;
		$array[$index+1] =~ s/\"//g;
		$array[2] = $array[$index+1]; # populate fast lookup
		$index += 2;
	}

	if ($config =~ /snmp-server contact ([\S ]+)/)
	{
		$array[$index] = "Contact";
		$array[$index+1] = $1;
		$array[$index+1] =~ s/\"//g;
		$array[3] = $array[$index+1]; # populate fast lookup
		$index += 2;
	}

	if ($config =~ /snmp-server location ([\S ]+)/)
	{
		$array[$index] = "Location";
		$array[$index+1] = $1;
		$array[$index+1] =~ s/\"//g;
		$array[5] = $array[$index+1]; # populate fast lookup
		$index += 2;
	}

	# Cisco IOS Software, Catalyst 4000 L3 Switch Software (cat4000-I5S-M), Version 12.2(25)EW, RELEASE SOFTWARE (fc1)
	if ($version =~ /system:[ \s]+version (\S+)/)
	{
		$array[4] = $1; # populate fast lookup
		$array[$index] = "OSVer";
		$array[$index+1] = $1;
		$index += 2;
	}

	if($version =~ /isco [\S ]+ processor [\S ]+ with (\S+)\/[\S]+ bytes of memory/ ||
	   $version =~ /isco [\S ]+ processor [\S ]+ with (\S+) bytes of memory/ ||
	   $version =~ /isco [\S ]+ processor with (\S+)\/[\S]+ bytes of memory/  ||
	   $version =~ /isco [\S ]+ processor with (\S+) bytes of memory/ ||
       $version =~ /isco [\S ]+ with (\S+)\/[\S]+ bytes of memory/ ||
       $version =~ /with\s+(\d+\s*\S+).*memory/)
	{
		$memory = $1;
		$array[$index] = "SystemMemory";
        if($memory =~ s/(\d+)\s*K/$1/i)
        {
            $memory *= 1024;
        }
        elsif($memory =~ s/(\d+)\s*M/$1/i)
        {
            $memory = $memory * 1024 * 1024;
        }
        $array[$index+1] = sprintf("%.0f",$memory); ##RLS
		#$array[$index+1] = sprintf("%d",$memory);
		$array[7] = $array[$index+1];
		$index += 2;
	}
	elsif ($version =~ /RAM (\d+) kB/)
	{
		$memory = $1;
		$memory *= 1024;
		$array[$index] = "SystemMemory";
        	$array[$index+1] = $memory; ##RLS
		$array[7] = $array[$index+1];
		$index += 2;
	}


	if($version =~ /\d+ +\d+ .*Supervisor\(active\) +(\S+) +\S+/ ||
	   $version =~ /cisco ([\S ]+) processor [\S ]+ with/ ||
	   $version =~ /cisco ([\S ]+) processor [\S ]+ with/ ||
	   $version =~ /cisco ([\S ]+) processor with / ||
	   $version =~ /cisco CRS-8\/S (\(\.*?\)) processor/ ||
	   $version =~ /cisco CRS-8\/S (\(\.*?\)) processor/ ||
	   $version =~ /(Motorola.*?)\s*with/)
	{
		$processor = $1;
		$array[$index] = "Processor";
		$array[$index+1] = $processor;
		$array[9] = $array[$index+1];
		$index += 2; 
	}

	if($version =~ /System image file is \"(\S+)\"/)  	 
	{ 	 
		$array[$index] = "SystemImage"; 	 
		$array[$index+1] = $1; 	 
		$index += 2;  	 
	}

	return @array;
}

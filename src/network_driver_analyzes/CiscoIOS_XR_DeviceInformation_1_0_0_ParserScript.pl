#! /usr/local/bin/perl

sub GetDeviceInfoTypesAndValues
{
	my($config,$version,$deviceType, $customSerialNumber,$power) = @_;
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

	my($series) = "";

	if ($version =~ /IOS \(tm\) (\S+) Software/)
	{
		$series = $1;
	}

	if ($version =~ /Model number: (\S+)/i)
	{
		$array[$index] = "Model";
		$array[$index+1] = $1;

		if ($series ne "")
		{
			$array[$index+1] .= " ($series series)";
		}

		$array[0] = $array[$index+1]; # populate fast lookup
		$index += 2;
	}
	elsif ($version =~ /cisco ([\S ]+?) *\([\S ]+\) processor/i ||
           $version =~ /Cisco ([\S\d]+) .*\(revision \S+\) with/ )
	{
		$array[$index] = "Model";
		$array[$index+1] = $1;

		if ($series ne "")
		{
			$array[$index+1] .= " ($series series)";
			$array[$index+1] =~ s/  / /g;
		}

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
        if($deviceType eq "WirelessAP" && $version =~ /Top Assembly Serial Number +: +(\S+)/){
    		$array[$index] = "SerialNumber";
    		$array[$index+1] = $1;
    		$array[6] = $1; # populate fast lookup
    		$index += 2;
        }
    	elsif ($version =~ /System serial number: (\S+)/)
    	{
    		$array[$index] = "SerialNumber";
    		$array[$index+1] = $1;
    		$array[6] = $1; # populate fast lookup
    		$index += 2;
    	}
    	elsif ($version =~ /Processor board ID (\w{5,}?)[\s,]/)
    	{
    		$array[$index] = "SerialNumber";
    		$array[$index+1] = $1;
    		$array[6] = $1; # populate fast lookup
    		$index += 2;
    	}
    	elsif ($version =~ /PCB Serial Number *: *(\S+)/)
    	{
    		$array[$index] = "SerialNumber";
    		$array[$index+1] = $1;
    		$array[6] = $1; # populate fast lookup
    		$index += 2;
    	}
	elsif ($version =~ /Serial number is (\S+)/)
	{
    		$array[$index] = "SerialNumber";
    		$array[$index+1] = $1;
    		$array[6] = $1; # populate fast lookup
    		$index += 2;
	}	
        elsif ($version =~ /Serial Number: +(\S+)/)
        {
                $array[$index] = "SerialNumber";
                $array[$index+1] = $1;
                $array[6] = $array[$index+1];
                $index += 2;
        }
        elsif ($version =~ /S\/N:? +(\S+)/)
        {
                $array[$index] = "SerialNumber";
                $array[$index+1] = $1;
                $array[6] = $array[$index+1];
                $index += 2;
        }
    }

	if ($config =~ /hostname (\S+)/)
	{
		$array[$index] = "Hostname";
		$array[$index+1] = $1;
		$array[$index+1] =~ s/\"//g;
		$array[2] = $array[$index+1]; # populate fast lookup
		$index += 2;
	}
	elsif ($config =~ /switchname[\s ](\S+)/)
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

	elsif ($config =~ /contact[ \s]+([\S\s]+?)[ ]*\n/ )
	{
	   $array[$index] = "Contact";
	   $array[$index+1] = $1;
	   $array[$index+1] =~ s/\"//g;
	   $array[3] = $array[$index+1];  # populate fast lookup
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

	elsif ($config =~ /[^\S]location[ \s]+([\S\s]+?)[ ]*\n/ )
	{
	   $array[$index] = "Location";
	   $array[$index+1] = $1;
	   $array[$index+1] =~ s/\"//g;
	   $array[5] = $array[$index+1];  # populate fast lookup
	   $index += 2;

	}

	# Cisco IOS Software, Catalyst 4000 L3 Switch Software (cat4000-I5S-M), Version 12.2(25)EW, RELEASE SOFTWARE (fc1)
	if ($version =~ /IOS \(tm\) ([\S ]+?), Version (\S+),/ || 
	    $version =~ /(Cisco IOS Software), [\S ]+ Version (\S+),/)
	{
		$array[4] = $2;
		$array[$index] = "OSVer";
		$array[$index+1] = $2;
		$index += 2;
	}
	elsif ($version =~ /system:[ \s]+version (\S+)/)
	{
		$array[4] = $1; # populate fast lookup
		$array[$index] = "OSVer";
		$array[$index+1] = $1;
		$index += 2;
	}
	elsif ($version =~ /version (\S+)[,\n]?/i)
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
       $version =~ /isco [\S ]+ with (\S+)\/[\S]+ bytes of memory/)
	{
		$memory = $1;
		$array[$index] = "SystemMemory";
        if($memory =~ s/(\d+)K/$1/)
        {
            $memory *= 1024;
        }
        elsif($memory =~ s/(\d+)M/$1/)
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
        	$array[$index+1] = $memory;
		$array[7] = $array[$index+1];
		$index += 2;
	}


	if($version =~ /\d+ +\d+ .*Supervisor\(active\) +(\S+) +\S+/ ||
	   $version =~ /cisco ([\S ]+) processor [\S ]+ with/ ||
	   $version =~ /cisco ([\S ]+) processor [\S ]+ with/ ||
	   $version =~ /cisco ([\S ]+) processor with / ||
	   $version =~ /cisco CRS-8\/S (\(\.*?\)) processor/ )
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

    my @serviceTypes = ();
    if($config =~ /router bgp/ )
    {
        my $type = "BGP";
        push(@serviceTypes, $type);
    }
    my @voipPatterns = ("fair-queue", "priority-group", "traffic-shape", "custom-queue", "\n +rate-limit");
    my $pattern = "";
    foreach $pattern (@voipPatterns)
    {
        if($config =~ /(no )*$pattern/)
        {
            if($1 eq "") { 
                my $type = "VoIP";
                push(@serviceTypes, $type);
            }
        }
    }
    if($config =~ /(mpls |mpls label|tag-switching )/)
    {
        my $type = "MPLS";
        push(@serviceTypes, $type);
    }

    if($power =~ /Watt/)
    {
        my $type = "Power";
        push(@serviceTypes, $type);
    }

    if($#serviceTypes >= 0)
    {
        my $serviceType = "";
        for($i = 0; $i <= $#serviceTypes; $i++)
        {
            if($i > 0) { $serviceType .= "|"; }
            $serviceType .= $serviceTypes[$i];
        }

        $array[$index] = "ServiceTypes";
        $array[$index+1] = $serviceType;
        $index+= 2;
    }

	return @array;
}

#! /usr/local/bin/perl

sub GetDeviceInfoTypesAndValues
{
	my($config,$deviceType, $customSerialNumber, $power) = @_;
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

	if ($config =~ /IOS \(tm\) (\S+) Software/)
	{
		$series = $1;
	}

	if ($config =~ /Manufactured As: (\S+)/)
	{
		$array[$index] = "Model";
		$array[$index+1] = $1;
		$array[0] = $array[$index+1]; # populate fast lookup
		$index += 2;
	}

	if($config =~ /(BOOTFLASH): .*Version ([\S ]+),/ ||
	   $config =~ /(BOOTFLASH|BOOTLDR|ROM): .*Version ([\S ]+),/ ||
	   $config =~ /(ROM): Bootstrap program is ([\S ]+)/ ||
	   $config =~ /(ROM): (\S+)/ )
	{
		$array[$index] = "ROMVer";
		$array[$index+1] = $2;
		$array[8] = $array[$index+1]; # populate fast lookup
		$index += 2;
	}

   if ($config =~ /SerialNumber: (\S+)/){
			##
			# ACNS
    		$array[$index] = "SerialNumber";
    		$array[$index+1] = $1;
    		$array[6] = $1; # populate fast lookup
    		$index += 2;
    }

	if ($config =~ /hostname (\S+)/)
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
 
	if ($config =~ /Application and Content Networking System Software Release (\S+)/)
	{
		$array[$index] = "OSVer";
		$array[$index+1] = $1;
		$array[4] = $array[$index+1]; # populate fast lookup
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
	elsif ($config =~ /\nlocation ([\S\s]+?)[ ]*\n/ )
	{
	   $array[$index] = "Location";
	   $array[$index+1] = $1;
	   $array[$index+1] =~ s/\"//g;
	   $array[5] = $array[$index+1];  # populate fast lookup
	   $index += 2;

	}
	if ($config =~ /(\d+) Mbytes of Physical memory/){
		$memory = $1;
		$array[$index] = "SystemMemory";
        $memory *= 1024 * 1024;
		$memory = $memory > 2147483647 ? 2147483647 : $memory;
        $array[$index+1] = sprintf("%.0f",$memory); ##RLS
		$array[7] = $array[$index+1];
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

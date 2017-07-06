#! /usr/local/bin/perl

sub stripCarriageReturns
{
	my($rawdata) = @_;

	$rawdata =~ s/[\r\x80\xC0]//g;

	return $rawdata;
}

sub removeMores
{
	my($rawdata) = @_;

	$rawdata = stripCarriageReturns($rawdata);
	$rawdata =~ s/ ?--More--[ \S]*[\s\cH]+\cH//g;
	##
	# ACNS
	$rawdata =~ s/\s*?--More--|\033\[K//g;
	return $rawdata;
}

sub stripLastLine
{
	my($rawdata) = @_;
	$rawdata =~ s/\n[\S ]+\n*$//;

	return $rawdata;
}

sub cleanupConfiguration
{
	my($config) = @_;
	my(@array) = ();
	
	$cleanConfig = removeMores($config);
	$cleanConfig = stripLastLine($cleanConfig);

	# ACE remove command
	$cleanConfig =~ s/show running-config\n//;
	$cleanConfig =~ s/show startup-config\n//;
	$cleanConfig =~ s/Generating configuration\.+\n//;

	# Remove leading and trailing linefeeds
	$cleanConfig =~ s/^\n+//;
	$cleanConfig =~ s/\n+$//;
	
	return $cleanConfig;
}

sub cleanupTFTPConfiguration
{
	my($config) = @_;

	# Remove leading and trailing linefeeds
	$config =~ s/^\n+//;
	$config =~ s/\n+$//;

	return $config;
}

sub cleanupVersion
{
	my($rawdata) = @_;

	if($rawdata =~ /<<OID<(1.3.6.1.2.1.1.1.0|sysDescr)>>>=/){
		$rawdata =~ s/<<OID<(1.3.6.1.2.1.1.1.0|sysDescr)>>>=//;
		$rawdata =~ s/^{//;
		$rawdata =~ s/}$//;
		$cleandata = $rawdata;
		if($cleandata =~ s/(<<OID<(1.3.6.1.2.1.1.2.0|sysObjectID)>>>=(\S+))//){
			$model = lookupModel($3);
			$cleandata .= "\nModel number: $model\n";
		}
			
	}
	else
	{
		$start = index($rawdata, "Cisco");
		$cleandata = substr($rawdata, $start);
		$cleandata = removeMores($cleandata);

		$cleandata = stripLastLine($cleandata);
	}

	return "_VERSION_INFO_\n" . $cleandata . "\n_END_VERSION_INFO_\n";
}

sub getSCPSupport
{
	my($rawdata) = @_;
    my $twelveThreePlus = "false";
    $cleandata = cleanupVersion($rawdata);

    if($cleandata =~ /IOS[\s\S]+?Version (\d+\.\d+)(\((\S+)\))?/)
    {
        $version = $1;
        $twelveThreePlus = "true" if($version >= 12.3);
    }

	return $twelveThreePlus;
}

sub getStartupSCPSupport
{
	my($scpSupport) = @_;

	return $scpSupport;
}

sub cleanupRouting
{
	my($rawdata) = @_;

	$cleandata = removeMores($rawdata);
	$cleandata = stripLastLine($cleandata);

	$start = 0;
	$extra = "";
	
	

	if($cleandata !~ /Gateway of last/){
		if($cleandata =~ /Invalid input detected/){
			$cleandata = "Layer 3 routing functionality is not available within this version of IOS.";
		}

	}
	
	if($cleandata !~ /([Ii]nvalid (input|command)|BGP not active)/gc)
	{
		if ($cleandata =~ /show ip bgp summary\n+/gc)
		{
			$start = pos($cleandata);
			$extra = "(BGP detected, showing BGP routing summary)\n"
		}
		elsif ($cleandata =~ /show bgp summary\n+/gc)
		{
			$start = pos($cleandata);
			$extra = "(BGP detected, showing BGP routing summary)\n";
		}
	}
	else
	{
		if ($cleandata =~ /show ip route\n+/gc)
		{
			$start = pos($cleandata);
		}
		elsif ($cleandata =~ /show route ipv4\n+/gc)
		{
			$start = pos($cleandata);
		}
	}
	pos($cleandata) = 0;

	if ($start > 0)
	{
		$cleandata = substr($cleandata, $start);
	}
	$cleandata = $extra . $cleandata;
	
	##
	# ACNS
	$cleandata =~ s/^show ip routes.*?\n//s;

	return $cleandata;
}

sub cleanupInterfaces
{
	my($rawdata) = @_;
	
	$cleandata = removeMores($rawdata);

	$cleandata =~ s/show interface(s?)\n//;
	$cleandata = stripLastLine($cleandata);

	return $cleandata;
}

sub cleanupOSPFNeighbors
{
	my($rawdata) = @_;

	$cleandata = removeMores($rawdata);
	$cleandata = stripLastLine($cleandata);
	$cleandata =~ s/show (ip )?ospf neighbor*.\n?//;

	##
	# on IOS-XR - RLS
	if($cleandata =~ /eighbor count/){
		$cleandata = $1 if $cleandata =~ /(Neighbors.*?otal neighbor count:\s+\d+)/s;	
	}
	if($cleandata =~ /Invalid input detected/){
		$cleandata = "OSPF functionality is not available within this version of IOS.";
	}

	return $cleandata;
}

sub cleanupModule
{
	my($rawdata) = @_;

	$start = index($rawdata, "Slot");
	$cleandata = substr($rawdata, $start);
	$cleandata = removeMores($rawdata);

	return $cleandata;
}

sub cleanupInventory
{
	my($rawdata) = @_;
	
	$cleandata = removeMores($rawdata);
	
	# Remove error and the prompt after it (if it occurs)
	$cleandata =~ s/\^[\s]*% Invalid input .*\s*(\S+#)?//g;
	$cleandata =~ s/\s*show hardware.*?\n//s;	##ACNS
	$cleandata =~ s/\s*show diag\n//g;
	$cleandata =~ s/\s*show module\n//g;
	$cleandata =~ s/\s*show version\n//g;
	$cleandata =~ s/\s*show hardware detail\n//g;
	$cleandata =~ s/\s*show gsr chassis\n//g;
	$cleandata =~ s/\s*show (c7200|c3600)\n//g;
	$cleandata =~ s/\^[\s]*% Invalid input .*\s*//g;
	$cleandata = stripLastLine($cleandata);

	return $cleandata;
}

sub cleanupFileSystem
{
	my($rawdata) = @_;
	my($cleandata) = "";

	$cleandata = removeMores($rawdata);
	$cleandata = stripLastLine($cleandata);

	return $cleandata;

}

sub getTarValue
{
	my ($config) = @_;
	my $value = "false";

	if($config =~ /\S+\.tar/)
	{
		$value = "true";
	}

	return $value;
}

sub getBootValue
{
	my ($config) = @_;
	my $value = "false";

	if($config =~ /\S+boot\S+/)
	{
		$value = "true";
	}

	return $value;
}

sub getDeploymentParsingSuccess
{
	my ($config) = @_;
	my $value = "true";

	if($config =~ /% Invalid input detected at/)
	{
		$value = "false";
	}

	return $value;
}

sub lookupModel
{
	my($oid) = @_;

	my %OIDS = (
		"1.3.6.1.4.1.9.1.1" => "ciscoGatewayServer",
		"1.3.6.1.4.1.9.1.2" => "ciscoTerminalServer",
		"1.3.6.1.4.1.9.1.3" => "ciscoTrouter",
		"1.3.6.1.4.1.9.1.4" => "ciscoProtocolTranslator",
		"1.3.6.1.4.1.9.1.5" => "ciscoIGS",
		"1.3.6.1.4.1.9.1.6" => "cisco3000",
		"1.3.6.1.4.1.9.1.7" => "cisco4000",
		"1.3.6.1.4.1.9.1.8" => "cisco7000",
		"1.3.6.1.4.1.9.1.9" => "ciscoCS500",
		"1.3.6.1.4.1.9.1.10" => "cisco2000",
		"1.3.6.1.4.1.9.1.11" => "ciscoAGSplus",
		"1.3.6.1.4.1.9.1.12" => "cisco7010",
		"1.3.6.1.4.1.9.1.13" => "cisco2500",
		"1.3.6.1.4.1.9.1.14" => "cisco4500",
		"1.3.6.1.4.1.9.1.15" => "cisco2102",
		"1.3.6.1.4.1.9.1.16" => "cisco2202",
		"1.3.6.1.4.1.9.1.17" => "cisco2501",
		"1.3.6.1.4.1.9.1.18" => "cisco2502",
		"1.3.6.1.4.1.9.1.19" => "cisco2503",
		"1.3.6.1.4.1.9.1.20" => "cisco2504",
		"1.3.6.1.4.1.9.1.21" => "cisco2505",
		"1.3.6.1.4.1.9.1.22" => "cisco2506",
		"1.3.6.1.4.1.9.1.23" => "cisco2507",
		"1.3.6.1.4.1.9.1.24" => "cisco2508",
		"1.3.6.1.4.1.9.1.25" => "cisco2509",
		"1.3.6.1.4.1.9.1.26" => "cisco2510",
		"1.3.6.1.4.1.9.1.27" => "cisco2511",
		"1.3.6.1.4.1.9.1.28" => "cisco2512",
		"1.3.6.1.4.1.9.1.29" => "cisco2513",
		"1.3.6.1.4.1.9.1.30" => "cisco2514",
		"1.3.6.1.4.1.9.1.31" => "cisco2515",
		"1.3.6.1.4.1.9.1.32" => "cisco3101",
		"1.3.6.1.4.1.9.1.33" => "cisco3102",
		"1.3.6.1.4.1.9.1.34" => "cisco3103",
		"1.3.6.1.4.1.9.1.35" => "cisco3104",
		"1.3.6.1.4.1.9.1.36" => "cisco3202",
		"1.3.6.1.4.1.9.1.37" => "cisco3204",
		"1.3.6.1.4.1.9.1.38" => "ciscoAccessProRC",
		"1.3.6.1.4.1.9.1.39" => "ciscoAccessProEC",
		"1.3.6.1.4.1.9.1.40" => "cisco1000",
		"1.3.6.1.4.1.9.1.41" => "cisco1003",
		"1.3.6.1.4.1.9.1.42" => "cisco2516",
		"1.3.6.1.4.1.9.1.43" => "cisco1020",
		"1.3.6.1.4.1.9.1.44" => "cisco1004",
		"1.3.6.1.4.1.9.1.45" => "cisco7507",
		"1.3.6.1.4.1.9.1.46" => "cisco7513",
		"1.3.6.1.4.1.9.1.47" => "cisco7506",
		"1.3.6.1.4.1.9.1.48" => "cisco7505",
		"1.3.6.1.4.1.9.1.49" => "cisco1005",
		"1.3.6.1.4.1.9.1.50" => "cisco4700",
		"1.3.6.1.4.1.9.1.51" => "ciscoPro1003",
		"1.3.6.1.4.1.9.1.52" => "ciscoPro1004",
		"1.3.6.1.4.1.9.1.53" => "ciscoPro1005",
		"1.3.6.1.4.1.9.1.54" => "ciscoPro1020",
		"1.3.6.1.4.1.9.1.55" => "ciscoPro2500PCE",
		"1.3.6.1.4.1.9.1.56" => "ciscoPro2501",
		"1.3.6.1.4.1.9.1.57" => "ciscoPro2503",
		"1.3.6.1.4.1.9.1.58" => "ciscoPro2505",
		"1.3.6.1.4.1.9.1.59" => "ciscoPro2507",
		"1.3.6.1.4.1.9.1.60" => "ciscoPro2509",
		"1.3.6.1.4.1.9.1.61" => "ciscoPro2511",
		"1.3.6.1.4.1.9.1.62" => "ciscoPro2514",
		"1.3.6.1.4.1.9.1.63" => "ciscoPro2516",
		"1.3.6.1.4.1.9.1.64" => "ciscoPro2519",
		"1.3.6.1.4.1.9.1.65" => "ciscoPro2521",
		"1.3.6.1.4.1.9.1.66" => "ciscoPro4500",
		"1.3.6.1.4.1.9.1.67" => "cisco2517",
		"1.3.6.1.4.1.9.1.68" => "cisco2518",
		"1.3.6.1.4.1.9.1.69" => "cisco2519",
		"1.3.6.1.4.1.9.1.70" => "cisco2520",
		"1.3.6.1.4.1.9.1.71" => "cisco2521",
		"1.3.6.1.4.1.9.1.72" => "cisco2522",
		"1.3.6.1.4.1.9.1.73" => "cisco2523",
		"1.3.6.1.4.1.9.1.74" => "cisco2524",
		"1.3.6.1.4.1.9.1.75" => "cisco2525",
		"1.3.6.1.4.1.9.1.76" => "ciscoPro751",
		"1.3.6.1.4.1.9.1.77" => "ciscoPro752",
		"1.3.6.1.4.1.9.1.78" => "ciscoPro753",
		"1.3.6.1.4.1.9.1.81" => "cisco751",
		"1.3.6.1.4.1.9.1.82" => "cisco752",
		"1.3.6.1.4.1.9.1.83" => "cisco753",
		"1.3.6.1.4.1.9.1.84" => "ciscoPro741",
		"1.3.6.1.4.1.9.1.85" => "ciscoPro742",
		"1.3.6.1.4.1.9.1.86" => "ciscoPro743",
		"1.3.6.1.4.1.9.1.87" => "ciscoPro744",
		"1.3.6.1.4.1.9.1.88" => "ciscoPro761",
		"1.3.6.1.4.1.9.1.89" => "ciscoPro762",
		"1.3.6.1.4.1.9.1.92" => "ciscoPro765",
		"1.3.6.1.4.1.9.1.93" => "ciscoPro766",
		"1.3.6.1.4.1.9.1.94" => "cisco741",
		"1.3.6.1.4.1.9.1.95" => "cisco742",
		"1.3.6.1.4.1.9.1.96" => "cisco743",
		"1.3.6.1.4.1.9.1.97" => "cisco744",
		"1.3.6.1.4.1.9.1.98" => "cisco761",
		"1.3.6.1.4.1.9.1.99" => "cisco762",
		"1.3.6.1.4.1.9.1.102" => "cisco765",
		"1.3.6.1.4.1.9.1.103" => "cisco766",
		"1.3.6.1.4.1.9.1.104" => "ciscoPro2520",
		"1.3.6.1.4.1.9.1.105" => "ciscoPro2522",
		"1.3.6.1.4.1.9.1.106" => "ciscoPro2524",
		"1.3.6.1.4.1.9.1.107" => "ciscoLS1010",
		"1.3.6.1.4.1.9.1.108" => "cisco7206",
		"1.3.6.1.4.1.9.1.109" => "ciscoAS5200",
		"1.3.6.1.4.1.9.1.110" => "cisco3640",
		"1.3.6.1.4.1.9.1.111" => "ciscoCatalyst3500",
		"1.3.6.1.4.1.9.1.112" => "ciscoWSX3011",
		"1.3.6.1.4.1.9.1.113" => "cisco1601",
		"1.3.6.1.4.1.9.1.114" => "cisco1602",
		"1.3.6.1.4.1.9.1.115" => "cisco1603",
		"1.3.6.1.4.1.9.1.116" => "cisco1604",
		"1.3.6.1.4.1.9.1.117" => "ciscoPro1601",
		"1.3.6.1.4.1.9.1.118" => "ciscoPro1602",
		"1.3.6.1.4.1.9.1.119" => "ciscoPro1603",
		"1.3.6.1.4.1.9.1.120" => "ciscoPro1604",
		"1.3.6.1.4.1.9.1.122" => "cisco3620",
		"1.3.6.1.4.1.9.1.123" => "ciscoPro3620",
		"1.3.6.1.4.1.9.1.124" => "ciscoPro3640",
		"1.3.6.1.4.1.9.1.125" => "cisco7204",
		"1.3.6.1.4.1.9.1.126" => "cisco771",
		"1.3.6.1.4.1.9.1.127" => "cisco772",
		"1.3.6.1.4.1.9.1.128" => "cisco775",
		"1.3.6.1.4.1.9.1.129" => "cisco776",
		"1.3.6.1.4.1.9.1.130" => "ciscoPro2502",
		"1.3.6.1.4.1.9.1.131" => "ciscoPro2504",
		"1.3.6.1.4.1.9.1.132" => "ciscoPro2506",
		"1.3.6.1.4.1.9.1.133" => "ciscoPro2508",
		"1.3.6.1.4.1.9.1.134" => "ciscoPro2510",
		"1.3.6.1.4.1.9.1.135" => "ciscoPro2512",
		"1.3.6.1.4.1.9.1.136" => "ciscoPro2513",
		"1.3.6.1.4.1.9.1.137" => "ciscoPro2515",
		"1.3.6.1.4.1.9.1.138" => "ciscoPro2517",
		"1.3.6.1.4.1.9.1.139" => "ciscoPro2518",
		"1.3.6.1.4.1.9.1.140" => "ciscoPro2523",
		"1.3.6.1.4.1.9.1.141" => "ciscoPro2525",
		"1.3.6.1.4.1.9.1.142" => "ciscoPro4700",
		"1.3.6.1.4.1.9.1.147" => "ciscoPro316T",
		"1.3.6.1.4.1.9.1.148" => "ciscoPro316C",
		"1.3.6.1.4.1.9.1.149" => "ciscoPro3116",
		"1.3.6.1.4.1.9.1.150" => "catalyst116T",
		"1.3.6.1.4.1.9.1.151" => "catalyst116C",
		"1.3.6.1.4.1.9.1.152" => "catalyst1116",
		"1.3.6.1.4.1.9.1.153" => "ciscoAS2509RJ",
		"1.3.6.1.4.1.9.1.154" => "ciscoAS2511RJ",
		"1.3.6.1.4.1.9.1.157" => "ciscoMC3810",
		"1.3.6.1.4.1.9.1.160" => "cisco1503",
		"1.3.6.1.4.1.9.1.161" => "cisco1502",
		"1.3.6.1.4.1.9.1.162" => "ciscoAS5300",
		"1.3.6.1.4.1.9.1.164" => "ciscoLS1015",
		"1.3.6.1.4.1.9.1.165" => "cisco2501FRADFX",
		"1.3.6.1.4.1.9.1.166" => "cisco2501LANFRADFX",
		"1.3.6.1.4.1.9.1.167" => "cisco2502LANFRADFX",
		"1.3.6.1.4.1.9.1.168" => "ciscoWSX5302",
		"1.3.6.1.4.1.9.1.169" => "ciscoFastHub216T",
		"1.3.6.1.4.1.9.1.170" => "catalyst2908xl",
		"1.3.6.1.4.1.9.1.171" => "catalyst2916m-xl",
		"1.3.6.1.4.1.9.1.172" => "cisco1605",
		"1.3.6.1.4.1.9.1.173" => "cisco12012",
		"1.3.6.1.4.1.9.1.175" => "catalyst1912C",
		"1.3.6.1.4.1.9.1.176" => "ciscoMicroWebServer2",
		"1.3.6.1.4.1.9.1.177" => "ciscoFastHubBMMTX",
		"1.3.6.1.4.1.9.1.178" => "ciscoFastHubBMMFX",
		"1.3.6.1.4.1.9.1.179" => "ciscoUBR7246",
		"1.3.6.1.4.1.9.1.180" => "cisco6400",
		"1.3.6.1.4.1.9.1.181" => "cisco12004",
		"1.3.6.1.4.1.9.1.182" => "cisco12008",
		"1.3.6.1.4.1.9.1.183" => "catalyst2924XL",
		"1.3.6.1.4.1.9.1.184" => "catalyst2924CXL",
		"1.3.6.1.4.1.9.1.185" => "cisco2610",
		"1.3.6.1.4.1.9.1.186" => "cisco2611",
		"1.3.6.1.4.1.9.1.187" => "cisco2612",
		"1.3.6.1.4.1.9.1.188" => "ciscoAS5800",
		"1.3.6.1.4.1.9.1.189" => "ciscoSC3640",
		"1.3.6.1.4.1.9.1.190" => "cisco8510",
		"1.3.6.1.4.1.9.1.191" => "ciscoUBR904",
		"1.3.6.1.4.1.9.1.192" => "cisco6200",
		"1.3.6.1.4.1.9.1.194" => "cisco7202",
		"1.3.6.1.4.1.9.1.195" => "cisco2613",
		"1.3.6.1.4.1.9.1.196" => "cisco8515",
		"1.3.6.1.4.1.9.1.197" => "catalyst9006",
		"1.3.6.1.4.1.9.1.198" => "catalyst9009",
		"1.3.6.1.4.1.9.1.199" => "ciscoRPM",
		"1.3.6.1.4.1.9.1.200" => "cisco1710",
		"1.3.6.1.4.1.9.1.201" => "cisco1720",
		"1.3.6.1.4.1.9.1.202" => "catalyst8540msr",
		"1.3.6.1.4.1.9.1.203" => "catalyst8540csr",
		"1.3.6.1.4.1.9.1.204" => "cisco7576",
		"1.3.6.1.4.1.9.1.205" => "cisco3660",
		"1.3.6.1.4.1.9.1.206" => "cisco1401",
		"1.3.6.1.4.1.9.1.208" => "cisco2620",
		"1.3.6.1.4.1.9.1.209" => "cisco2621",
		"1.3.6.1.4.1.9.1.210" => "ciscoUBR7223",
		"1.3.6.1.4.1.9.1.211" => "cisco6400Nrp",
		"1.3.6.1.4.1.9.1.212" => "cisco801",
		"1.3.6.1.4.1.9.1.213" => "cisco802",
		"1.3.6.1.4.1.9.1.214" => "cisco803",
		"1.3.6.1.4.1.9.1.215" => "cisco804",
		"1.3.6.1.4.1.9.1.216" => "cisco1750",
		"1.3.6.1.4.1.9.1.217" => "catalyst2924XLv",
		"1.3.6.1.4.1.9.1.218" => "catalyst2924CXLv",
		"1.3.6.1.4.1.9.1.219" => "catalyst2912XL",
		"1.3.6.1.4.1.9.1.220" => "catalyst2924MXL",
		"1.3.6.1.4.1.9.1.221" => "catalyst2912MfXL",
		"1.3.6.1.4.1.9.1.222" => "cisco7206VXR",
		"1.3.6.1.4.1.9.1.223" => "cisco7204VXR",
		"1.3.6.1.4.1.9.1.224" => "cisco1538M",
		"1.3.6.1.4.1.9.1.225" => "cisco1548M",
		"1.3.6.1.4.1.9.1.226" => "ciscoFasthub100",
		"1.3.6.1.4.1.9.1.227" => "ciscoPIXFirewall",
		"1.3.6.1.4.1.9.1.228" => "ciscoMGX8850",
		"1.3.6.1.4.1.9.1.229" => "ciscoMGX8830",
		"1.3.6.1.4.1.9.1.230" => "catalyst8510msr",
		"1.3.6.1.4.1.9.1.231" => "catalyst8515msr",
		"1.3.6.1.4.1.9.1.232" => "ciscoIGX8410",
		"1.3.6.1.4.1.9.1.233" => "ciscoIGX8420",
		"1.3.6.1.4.1.9.1.234" => "ciscoIGX8430",
		"1.3.6.1.4.1.9.1.235" => "ciscoIGX8450",
		"1.3.6.1.4.1.9.1.237" => "ciscoBPX8620",
		"1.3.6.1.4.1.9.1.238" => "ciscoBPX8650",
		"1.3.6.1.4.1.9.1.239" => "ciscoBPX8680",
		"1.3.6.1.4.1.9.1.240" => "ciscoCacheEngine",
		"1.3.6.1.4.1.9.1.241" => "ciscoCat6000",
		"1.3.6.1.4.1.9.1.242" => "ciscoBPXSes",
		"1.3.6.1.4.1.9.1.243" => "ciscoIGXSes",
		"1.3.6.1.4.1.9.1.244" => "ciscoLocalDirector",
		"1.3.6.1.4.1.9.1.245" => "cisco805",
		"1.3.6.1.4.1.9.1.246" => "catalyst3508GXL",
		"1.3.6.1.4.1.9.1.247" => "catalyst3512XL",
		"1.3.6.1.4.1.9.1.248" => "catalyst3524XL",
		"1.3.6.1.4.1.9.1.249" => "cisco1407",
		"1.3.6.1.4.1.9.1.250" => "cisco1417",
		"1.3.6.1.4.1.9.1.251" => "cisco6100",
		"1.3.6.1.4.1.9.1.252" => "cisco6130",
		"1.3.6.1.4.1.9.1.253" => "cisco6260",
		"1.3.6.1.4.1.9.1.254" => "ciscoOpticalRegenerator",
		"1.3.6.1.4.1.9.1.255" => "ciscoUBR924",
		"1.3.6.1.4.1.9.1.256" => "ciscoWSX6302Msm",
		"1.3.6.1.4.1.9.1.257" => "catalyst5kRsfc",
		"1.3.6.1.4.1.9.1.258" => "catalyst6kMsfc",
		"1.3.6.1.4.1.9.1.259" => "cisco7120Quadt1",
		"1.3.6.1.4.1.9.1.260" => "cisco7120T3",
		"1.3.6.1.4.1.9.1.261" => "cisco7120E3",
		"1.3.6.1.4.1.9.1.262" => "cisco7120At3",
		"1.3.6.1.4.1.9.1.263" => "cisco7120Ae3",
		"1.3.6.1.4.1.9.1.264" => "cisco7120Smi3",
		"1.3.6.1.4.1.9.1.265" => "cisco7140Dualt3",
		"1.3.6.1.4.1.9.1.266" => "cisco7140Duale3",
		"1.3.6.1.4.1.9.1.267" => "cisco7140Dualat3",
		"1.3.6.1.4.1.9.1.268" => "cisco7140Dualae3",
		"1.3.6.1.4.1.9.1.269" => "cisco7140Dualmm3",
		"1.3.6.1.4.1.9.1.270" => "cisco827QuadV",
		"1.3.6.1.4.1.9.1.271" => "ciscoUBR7246VXR",
		"1.3.6.1.4.1.9.1.272" => "cisco10400",
		"1.3.6.1.4.1.9.1.273" => "cisco12016",
		"1.3.6.1.4.1.9.1.274" => "ciscoAs5400",
		"1.3.6.1.4.1.9.1.275" => "cat2948gL3",
		"1.3.6.1.4.1.9.1.276" => "cisco7140Octt1",
		"1.3.6.1.4.1.9.1.277" => "cisco7140Dualfe",
		"1.3.6.1.4.1.9.1.278" => "cat3548XL",
		"1.3.6.1.4.1.9.1.279" => "ciscoVG200",
		"1.3.6.1.4.1.9.1.280" => "cat6006",
		"1.3.6.1.4.1.9.1.281" => "cat6009",
		"1.3.6.1.4.1.9.1.282" => "cat6506",
		"1.3.6.1.4.1.9.1.283" => "cat6509",
		"1.3.6.1.4.1.9.1.284" => "cisco827",
		"1.3.6.1.4.1.9.1.285" => "ciscoManagementEngine1100",
		"1.3.6.1.4.1.9.1.286" => "ciscoMc3810V3",
		"1.3.6.1.4.1.9.1.287" => "cat3524tXLEn",
		"1.3.6.1.4.1.9.1.288" => "cisco7507z",
		"1.3.6.1.4.1.9.1.289" => "cisco7513z",
		"1.3.6.1.4.1.9.1.290" => "cisco7507mx",
		"1.3.6.1.4.1.9.1.291" => "cisco7513mx",
		"1.3.6.1.4.1.9.1.292" => "ciscoUBR912C",
		"1.3.6.1.4.1.9.1.293" => "ciscoUBR912S",
		"1.3.6.1.4.1.9.1.294" => "ciscoUBR914",
		"1.3.6.1.4.1.9.1.295" => "cisco802J",
		"1.3.6.1.4.1.9.1.296" => "cisco804J",
		"1.3.6.1.4.1.9.1.297" => "cisco6160",
		"1.3.6.1.4.1.9.1.298" => "cat4908gL3",
		"1.3.6.1.4.1.9.1.299" => "cisco6015",
		"1.3.6.1.4.1.9.1.300" => "cat4232L3",
		"1.3.6.1.4.1.9.1.301" => "catalyst6kMsfc2",
		"1.3.6.1.4.1.9.1.302" => "cisco7750Mrp200",
		"1.3.6.1.4.1.9.1.303" => "cisco7750Ssp80",
		"1.3.6.1.4.1.9.1.304" => "ciscoMGX8230",
		"1.3.6.1.4.1.9.1.305" => "ciscoMGX8250",
		"1.3.6.1.4.1.9.1.306" => "ciscoCVA122",
		"1.3.6.1.4.1.9.1.307" => "ciscoCVA124",
		"1.3.6.1.4.1.9.1.308" => "ciscoAs5850",
		"1.3.6.1.4.1.9.1.310" => "cat6509Sp",
		"1.3.6.1.4.1.9.1.311" => "ciscoMGX8240",
		"1.3.6.1.4.1.9.1.312" => "cat4840gL3",
		"1.3.6.1.4.1.9.1.313" => "ciscoAS5350",
		"1.3.6.1.4.1.9.1.314" => "cisco7750",
		"1.3.6.1.4.1.9.1.315" => "ciscoMGX8950",
		"1.3.6.1.4.1.9.1.316" => "ciscoUBR925",
		"1.3.6.1.4.1.9.1.317" => "ciscoUBR10012",
		"1.3.6.1.4.1.9.1.318" => "catalyst4kGateway",
		"1.3.6.1.4.1.9.1.319" => "cisco2650",
		"1.3.6.1.4.1.9.1.320" => "cisco2651",
		"1.3.6.1.4.1.9.1.321" => "cisco826QuadV",
		"1.3.6.1.4.1.9.1.322" => "cisco826",
		"1.3.6.1.4.1.9.1.323" => "catalyst295012",
		"1.3.6.1.4.1.9.1.324" => "catalyst295024",
		"1.3.6.1.4.1.9.1.325" => "catalyst295024C",
		"1.3.6.1.4.1.9.1.326" => "cisco1751",
		"1.3.6.1.4.1.9.1.329" => "cisco626",
		"1.3.6.1.4.1.9.1.330" => "cisco627",
		"1.3.6.1.4.1.9.1.331" => "cisco633",
		"1.3.6.1.4.1.9.1.332" => "cisco673",
		"1.3.6.1.4.1.9.1.333" => "cisco675",
		"1.3.6.1.4.1.9.1.334" => "cisco675e",
		"1.3.6.1.4.1.9.1.335" => "cisco676",
		"1.3.6.1.4.1.9.1.336" => "cisco677",
		"1.3.6.1.4.1.9.1.337" => "cisco678",
		"1.3.6.1.4.1.9.1.338" => "cisco3661Ac",
		"1.3.6.1.4.1.9.1.339" => "cisco3661Dc",
		"1.3.6.1.4.1.9.1.340" => "cisco3662Ac",
		"1.3.6.1.4.1.9.1.341" => "cisco3662Dc",
		"1.3.6.1.4.1.9.1.342" => "cisco3662AcCo",
		"1.3.6.1.4.1.9.1.343" => "cisco3662DcCo",
		"1.3.6.1.4.1.9.1.344" => "ciscoUBR7111",
		"1.3.6.1.4.1.9.1.345" => "ciscoUBR7111E",
		"1.3.6.1.4.1.9.1.346" => "ciscoUBR7114",
		"1.3.6.1.4.1.9.1.347" => "ciscoUBR7114E",
		"1.3.6.1.4.1.9.1.348" => "cisco12010",
		"1.3.6.1.4.1.9.1.349" => "cisco8110",
		"1.3.6.1.4.1.9.1.351" => "ciscoUBR905",
		"1.3.6.1.4.1.9.1.353" => "ciscoSOHO77",
		"1.3.6.1.4.1.9.1.354" => "ciscoSOHO76",
		"1.3.6.1.4.1.9.1.355" => "cisco7150Dualfe",
		"1.3.6.1.4.1.9.1.356" => "cisco7150Octt1",
		"1.3.6.1.4.1.9.1.357" => "cisco7150Dualt3",
		"1.3.6.1.4.1.9.1.358" => "ciscoOlympus",
		"1.3.6.1.4.1.9.1.359" => "catalyst2950t24",
		"1.3.6.1.4.1.9.1.360" => "ciscoVPS1110",
		"1.3.6.1.4.1.9.1.361" => "ciscoContentEngine",
		"1.3.6.1.4.1.9.1.362" => "ciscoIAD2420",
		"1.3.6.1.4.1.9.1.363" => "cisco677i",
		"1.3.6.1.4.1.9.1.364" => "cisco674",
		"1.3.6.1.4.1.9.1.365" => "ciscoDPA7630",
		"1.3.6.1.4.1.9.1.366" => "catalyst355024",
		"1.3.6.1.4.1.9.1.367" => "catalyst355048",
		"1.3.6.1.4.1.9.1.368" => "catalyst355012T",
		"1.3.6.1.4.1.9.1.369" => "catalyst2924LREXL",
		"1.3.6.1.4.1.9.1.370" => "catalyst2912LREXL",
		"1.3.6.1.4.1.9.1.371" => "ciscoCVA122E",
		"1.3.6.1.4.1.9.1.372" => "ciscoCVA124E",
		"1.3.6.1.4.1.9.1.373" => "ciscoURM",
		"1.3.6.1.4.1.9.1.374" => "ciscoURM2FE",
		"1.3.6.1.4.1.9.1.375" => "ciscoURM2FE2V",
		"1.3.6.1.4.1.9.1.376" => "cisco7401VXR",
		"1.3.6.1.4.1.9.1.379" => "ciscoCAP340",
		"1.3.6.1.4.1.9.1.380" => "ciscoCAP350",
		"1.3.6.1.4.1.9.1.381" => "ciscoDPA7610",
		"1.3.6.1.4.1.9.1.382" => "cisco828",
		"1.3.6.1.4.1.9.1.384" => "cisco806",
		"1.3.6.1.4.1.9.1.385" => "cisco12416",
		"1.3.6.1.4.1.9.1.386" => "cat2948gL3Dc",
		"1.3.6.1.4.1.9.1.387" => "cat4908gL3Dc",
		"1.3.6.1.4.1.9.1.388" => "cisco12406",
		"1.3.6.1.4.1.9.1.389" => "ciscoPIXFirewall506",
		"1.3.6.1.4.1.9.1.390" => "ciscoPIXFirewall515",
		"1.3.6.1.4.1.9.1.391" => "ciscoPIXFirewall520",
		"1.3.6.1.4.1.9.1.392" => "ciscoPIXFirewall525",
		"1.3.6.1.4.1.9.1.393" => "ciscoPIXFirewall535",
		"1.3.6.1.4.1.9.1.394" => "cisco12410",
		"1.3.6.1.4.1.9.1.395" => "cisco811",
		"1.3.6.1.4.1.9.1.396" => "cisco813",
		"1.3.6.1.4.1.9.1.397" => "cisco10720",
		"1.3.6.1.4.1.9.1.398" => "ciscoMWR1900",
		"1.3.6.1.4.1.9.1.399" => "cisco4224",
		"1.3.6.1.4.1.9.1.400" => "ciscoWSC6513",
		"1.3.6.1.4.1.9.1.401" => "cisco7603",
		"1.3.6.1.4.1.9.1.402" => "cisco7606",
		"1.3.6.1.4.1.9.1.403" => "cisco7401ASR",
		"1.3.6.1.4.1.9.1.404" => "ciscoVG248",
		"1.3.6.1.4.1.9.1.405" => "ciscoHSE",
		"1.3.6.1.4.1.9.1.406" => "ciscoONS15540ESP",
		"1.3.6.1.4.1.9.1.407" => "ciscoSN5420",
		"1.3.6.1.4.1.9.1.409" => "ciscoCe507",
		"1.3.6.1.4.1.9.1.410" => "ciscoCe560",
		"1.3.6.1.4.1.9.1.411" => "ciscoCe590",
		"1.3.6.1.4.1.9.1.412" => "ciscoCe7320",
		"1.3.6.1.4.1.9.1.413" => "cisco2691",
		"1.3.6.1.4.1.9.1.414" => "cisco3725",
		"1.3.6.1.4.1.9.1.416" => "cisco1760",
		"1.3.6.1.4.1.9.1.417" => "ciscoPIXFirewall501",
		"1.3.6.1.4.1.9.1.418" => "cisco2610M",
		"1.3.6.1.4.1.9.1.419" => "cisco2611M",
		"1.3.6.1.4.1.9.1.423" => "cisco12404",
		"1.3.6.1.4.1.9.1.424" => "cisco9004",
		"1.3.6.1.4.1.9.1.425" => "cisco3631Co",
		"1.3.6.1.4.1.9.1.427" => "catalyst295012G",
		"1.3.6.1.4.1.9.1.428" => "catalyst295024G",
		"1.3.6.1.4.1.9.1.429" => "catalyst295048G",
		"1.3.6.1.4.1.9.1.430" => "catalyst295024S",
		"1.3.6.1.4.1.9.1.431" => "catalyst355012G",
		"1.3.6.1.4.1.9.1.432" => "ciscoCE507AV",
		"1.3.6.1.4.1.9.1.433" => "ciscoCE560AV",
		"1.3.6.1.4.1.9.1.434" => "ciscoIE2105",
		"1.3.6.1.4.1.9.1.435" => "ciscoMGX8850Pxm1E",
		"1.3.6.1.4.1.9.1.436" => "cisco3745",
		"1.3.6.1.4.1.9.1.437" => "cisco10005",
		"1.3.6.1.4.1.9.1.438" => "cisco10008",
		"1.3.6.1.4.1.9.1.439" => "cisco7304",
		"1.3.6.1.4.1.9.1.440" => "ciscoRpmXf",
		"1.3.6.1.4.1.9.1.444" => "cisco1721",
		"1.3.6.1.4.1.9.1.446" => "cisco827H",
		"1.3.6.1.4.1.9.1.448" => "cat4006",
		"1.3.6.1.4.1.9.1.449" => "ciscoWSC6503",
		"1.3.6.1.4.1.9.1.450" => "ciscoPIXFirewall506E",
		"1.3.6.1.4.1.9.1.451" => "ciscoPIXFirewall515E",
		"1.3.6.1.4.1.9.1.452" => "cat355024Dc",
		"1.3.6.1.4.1.9.1.453" => "cat355024Mmf",
		"1.3.6.1.4.1.9.1.454" => "ciscoCE2636",
		"1.3.6.1.4.1.9.1.455" => "ciscoDwCE",
		"1.3.6.1.4.1.9.1.456" => "cisco7750Mrp300",
		"1.3.6.1.4.1.9.1.457" => "ciscoRPMPR",
		"1.3.6.1.4.1.9.1.458" => "cisco14MGX8830Pxm1E",
		"1.3.6.1.4.1.9.1.459" => "ciscoWlse",
		"1.3.6.1.4.1.9.1.464" => "cisco6400UAC",
		"1.3.6.1.4.1.9.1.474" => "ciscoAIRAP1200",
		"1.3.6.1.4.1.9.1.475" => "ciscoSN5428",
		"1.3.6.1.4.1.9.1.466" => "cisco2610XM",
		"1.3.6.1.4.1.9.1.467" => "cisco2611XM",
		"1.3.6.1.4.1.9.1.468" => "cisco2620XM",
		"1.3.6.1.4.1.9.1.469" => "cisco2621XM",
		"1.3.6.1.4.1.9.1.470" => "cisco2650XM",
		"1.3.6.1.4.1.9.1.471" => "cisco2651XM",
		"1.3.6.1.4.1.9.1.472" => "catalyst295024GDC",
		"1.3.6.1.4.1.9.1.476" => "cisco7301",
		"1.3.6.1.4.1.9.1.479" => "cisco3250",
		"1.3.6.1.4.1.9.1.480" => "catalyst295024SX",
		"1.3.6.1.4.1.9.1.481" => "ciscoONS15540ESPx",
		"1.3.6.1.4.1.9.1.482" => "catalyst295024LRESt",
		"1.3.6.1.4.1.9.1.483" => "catalyst29508LRESt",
		"1.3.6.1.4.1.9.1.484" => "catalyst295024LREG",
		"1.3.6.1.4.1.9.1.485" => "catalyst355024PWR",
		"1.3.6.1.4.1.9.1.486" => "ciscoCDM4630",
		"1.3.6.1.4.1.9.1.487" => "ciscoCDM4650",
		"1.3.6.1.4.1.9.1.488" => "catalyst2955T12",
		"1.3.6.1.4.1.9.1.489" => "catalyst2955C12",
		"1.3.6.1.4.1.9.1.490" => "ciscoCE508",
		"1.3.6.1.4.1.9.1.491" => "ciscoCE565",
		"1.3.6.1.4.1.9.1.492" => "ciscoCE7325",
		"1.3.6.1.4.1.9.1.493" => "ciscoONS15454",
		"1.3.6.1.4.1.9.1.494" => "ciscoONS15327",
		"1.3.6.1.4.1.9.1.495" => "cisco837",
		"1.3.6.1.4.1.9.1.496" => "ciscoSOHO97",
		"1.3.6.1.4.1.9.1.497" => "cisco831",
		"1.3.6.1.4.1.9.1.498" => "ciscoSOHO91",
		"1.3.6.1.4.1.9.1.499" => "cisco836",
		"1.3.6.1.4.1.9.1.500" => "ciscoSOHO96",
		"1.3.6.1.4.1.9.1.501" => "cat4507",
		"1.3.6.1.4.1.9.1.502" => "cat4506",
		"1.3.6.1.4.1.9.1.503" => "cat4503",
		"1.3.6.1.4.1.9.1.504" => "ciscoCE7305",
		"1.3.6.1.4.1.9.1.505" => "ciscoCE510",
		"1.3.6.1.4.1.9.1.507" => "ciscoAIRAP1100",
		"1.3.6.1.4.1.9.1.508" => "catalyst2955S12",
		"1.3.6.1.4.1.9.1.509" => "cisco7609",
		"1.3.6.1.4.1.9.1.511" => "catalyst375024",
		"1.3.6.1.4.1.9.1.512" => "catalyst375048",
		"1.3.6.1.4.1.9.1.513" => "catalyst375024TS",
		"1.3.6.1.4.1.9.1.514" => "catalyst375024T",
		"1.3.6.1.4.1.9.1.516" => "catalyst37xxStack",
		"1.3.6.1.4.1.9.1.517" => "ciscoGSS",
		"1.3.6.1.4.1.9.1.518" => "ciscoPrimaryGSSM",
		"1.3.6.1.4.1.9.1.519" => "ciscoStandbyGSSM",
		"1.3.6.1.4.1.9.1.520" => "ciscoMWR1941DC",
		"1.3.6.1.4.1.9.1.521" => "ciscoDSC9216K9",
		"1.3.6.1.4.1.9.1.522" => "cat6500FirewallSm",
		"1.3.6.1.4.1.9.1.524" => "ciscoCSM",
		"1.3.6.1.4.1.9.1.525" => "ciscoAIRAP1210",
		"1.3.6.1.4.1.9.1.527" => "catalyst297024",
		"1.3.6.1.4.1.9.1.528" => "cisco7613",
		"1.3.6.1.4.1.9.1.530" => "catalyst3750Ge12Sfp",
		"1.3.6.1.4.1.9.1.531" => "ciscoCR4430",
		"1.3.6.1.4.1.9.1.532" => "ciscoCR4450",
		"1.3.6.1.4.1.9.1.533" => "ciscoAIRBR1410",
		"1.3.6.1.4.1.9.1.534" => "ciscoWSC6509neba",
		"1.3.6.1.4.1.9.1.537" => "catalyst4510",
		"1.3.6.1.4.1.9.1.538" => "cisco1711",
		"1.3.6.1.4.1.9.1.539" => "cisco1712",
		"1.3.6.1.4.1.9.1.540" => "catalyst29408TT",
		"1.3.6.1.4.1.9.1.542" => "catalyst29408TF",
		"1.3.6.1.4.1.9.1.543" => "cisco3825",
		"1.3.6.1.4.1.9.1.544" => "cisco3845",
		"1.3.6.1.4.1.9.1.545" => "cisco2430Iad24Fxs",
		"1.3.6.1.4.1.9.1.546" => "cisco2431Iad8Fxs",
		"1.3.6.1.4.1.9.1.547" => "cisco2431Iad16Fxs",
		"1.3.6.1.4.1.9.1.548" => "cisco2431Iad1T1E1",
		"1.3.6.1.4.1.9.1.549" => "cisco2432Iad24Fxs",
		"1.3.6.1.4.1.9.1.550" => "cisco1701ADSLBRI",
		"1.3.6.1.4.1.9.1.551" => "catalyst2950St24LRE997",
		"1.3.6.1.4.1.9.1.552" => "ciscoAirAp350IOS",
		"1.3.6.1.4.1.9.1.553" => "cisco3220",
		"1.3.6.1.4.1.9.1.554" => "cat6500SslSm",
		"1.3.6.1.4.1.9.1.555" => "ciscoSIMSE",
		"1.3.6.1.4.1.9.1.556" => "ciscoESSE",
		"1.3.6.1.4.1.9.1.557" => "catalyst6kSup720",
		"1.3.6.1.4.1.9.1.559" => "catalyst295048T",
		"1.3.6.1.4.1.9.1.560" => "catalyst295048SX",
		"1.3.6.1.4.1.9.1.561" => "catalyst297024TS",
		"1.3.6.1.4.1.9.1.562" => "ciscoNmNam",
		"1.3.6.1.4.1.9.1.563" => "catalyst356024PS",
		"1.3.6.1.4.1.9.1.564" => "catalyst356048PS",
		"1.3.6.1.4.1.9.1.565" => "ciscoAIRBR1300",
		"1.3.6.1.4.1.9.1.574" => "catalyst375024ME",
		"1.3.6.1.4.1.9.1.575" => "catalyst4000NAM",
		"1.3.6.1.4.1.9.1.576" => "cisco2811",
		"1.3.6.1.4.1.9.1.577" => "cisco2821",
		"1.3.6.1.4.1.9.1.578" => "cisco2851",
		"1.3.6.1.4.1.9.1.590" => "cisco12006",
		"1.3.6.1.4.1.9.1.591" => "catalyst3750G16TD",
		"1.3.6.1.4.1.9.1.592" => "ciscoIGESM",
		"1.3.6.1.4.1.9.1.593" => "ciscoCCM",
		"1.3.6.1.4.1.9.1.595" => "ciscoCe511K9",
		"1.3.6.1.4.1.9.1.596" => "ciscoCe566K9",
		"1.3.6.1.4.1.9.1.598" => "ciscoMGX8880",
		"1.3.6.1.4.1.9.1.599" => "ciscoWsSvcWLAN1K9",
		"1.3.6.1.4.1.9.1.600" => "ciscoCe7306K9",
		"1.3.6.1.4.1.9.1.601" => "ciscoCe7326K9",
		"1.3.6.1.4.1.9.1.606" => "ciscoBMGX8830Pxm45",
		"1.3.6.1.4.1.9.1.607" => "ciscoBMGX8830Pxm1E",
		"1.3.6.1.4.1.9.1.608" => "ciscoBMGX8850Pxm45",
		"1.3.6.1.4.1.9.1.609" => "ciscoBMGX8850Pxm1E",
		"1.3.6.1.4.1.9.1.611" => "ciscoNetworkRegistrar",
		"1.3.6.1.4.1.9.1.612" => "ciscoCe501K9",
		"1.3.6.1.4.1.9.1.618" => "ciscoAIRAP1130",
		"1.3.6.1.4.1.9.1.619" => "cisco2801",
		"1.3.6.1.4.1.9.1.620" => "cisco1841",
		"1.3.6.1.4.1.9.1.621" => "ciscoWsSvcMWAM1",
		"1.3.6.1.4.1.9.1.622" => "ciscoNMCUE",
		"1.3.6.1.4.1.9.1.623" => "ciscoAIMCUE",
		"1.3.6.1.4.1.9.1.626" => "catalyst4948",
		"1.3.6.1.4.1.9.1.630" => "ciscoWLSE1130",
		"1.3.6.1.4.1.9.1.631" => "ciscoWLSE1030",
		"1.3.6.1.4.1.9.1.632" => "ciscoHSE1140",
		"1.3.6.1.4.1.9.1.643" => "CiscoCRS",
		"1.3.6.1.4.1.9.1.645" => "ciscoIDS4210",
		"1.3.6.1.4.1.9.1.646" => "ciscoIDS4215",
		"1.3.6.1.4.1.9.1.647" => "ciscoIDS4235",
		"1.3.6.1.4.1.9.1.648" => "ciscoIPS4240",
		"1.3.6.1.4.1.9.1.649" => "ciscoIDS4250",
		"1.3.6.1.4.1.9.1.650" => "ciscoIDS4250SX",
		"1.3.6.1.4.1.9.1.651" => "ciscoIDS4250XL",
		"1.3.6.1.4.1.9.1.652" => "ciscoIPS4255",
		"1.3.6.1.4.1.9.1.653" => "ciscoIDSIDSM2",
		"1.3.6.1.4.1.9.1.654" => "ciscoIDSNMCIDS",
		"1.3.6.1.4.1.9.1.655" => "ciscoIPSSSM20",
		"1.3.6.1.4.1.9.1.661" => "ciscoFE6326K9",
		"1.3.6.1.4.1.9.1.662" => "ciscoIPSSSM10",
		"1.3.6.1.4.1.9.1.663" => "ciscoNme16Es1Ge",
		"1.3.6.1.4.1.9.1.664" => "ciscoNmeX24Es1Ge",
		"1.3.6.1.4.1.9.1.665" => "ciscoNmeXd24Es2St",
		"1.3.6.1.4.1.9.1.666" => "ciscoNmeXd48Es2Ge",
		"1.3.6.1.4.1.9.1.668" => "ciscoAs5400XM",
		"1.3.6.1.4.1.9.1.679" => "ciscoAs5350XM",
		"1.3.6.1.4.1.9.1.680" => "ciscoFe7326K9",
		"1.3.6.1.4.1.9.1.681" => "ciscoFe511K9",
		"1.3.6.1.4.1.9.1.682" => "ciscoSCEDispatcher",
		"1.3.6.1.4.1.9.1.683" => "ciscoSCE1000",
		"1.3.6.1.4.1.9.1.684" => "ciscoSCE2000",
		"1.3.6.1.4.1.9.1.686" => "ciscoDSC9120CLK9",
		"1.3.6.1.4.1.9.1.687" => "ciscoFe611K9",
	);

	# Try to make the model look more like the CLI version of the model
	$value = $OIDS{$oid};
	$value =~ s/(cisco|catalyst)//;
	return $value;
	
		
}

sub cleanupTopology
{
	my ($rawdata) = @_;
	
	$rawdata = removeMores($rawdata);
	
	# process
	$rawdata =~ s/(^|\n)show arp\n//;
	$rawdata =~ s/\n[\S ]+?show mac-address-table\n/\n\n/;
	
	# strip away any errors indicating lack of support
	$rawdata =~ s/\n +\^\n//;
	$rawdata =~ s/\n\% Invalid input detected at .*//;
	$rawdata =~ s/\n\% invalid command detected at .*//;
		
	# strip away any non-valuable lines
	$rawdata =~ s/\n All +[\d\.a-f]+ +STATIC +CPU//g;
	$rawdata =~ s/\nTotal Mac Addresses for this criterion: \d+//;
	$rawdata = stripLastLine($rawdata) . "\n";
	
	return $rawdata;
}

sub setupScriptConfiguration {

	my ($rawdata) = @_;
	
    return $rawdata . "\nend\n";

}

# Case for bug 8661
#print cleanupFileSystem("
#prompt# dir /all 
#Directory of flash:/ 
#
#     1  -rw-     7673516                    <no date>  [c831-k9o3y6-mz.124-1.bin] 
#
#12320764 bytes total (4647184 bytes free) 
#Spoke1# dir flash: 
#Directory of flash:/ 
#
#No files in directory 
#
#12320764 bytes total (4647184 bytes free) 
#Spoke1# ");
#
#print "\n\n";

# Case for bug 8171
#print "Test 2:\n" . cleanupFileSystem("
#prompt# dir /all
#Directory of flash:/all
#
#No such file
#
#3612672 bytes total (632832 bytes free)
#prompt# dir flash:
#Directory of flash:/
#
#2  -rwx     1162888   Mar 01 1993 21:15:03  c3500XL-c3h2-mz-112.8.5-SA6.bin
#3  -rwx         616   Mar 01 1993 00:00:20  vlan.dat
#4  ---x        3892   Mar 23 1993 03:38:32  config.text
#5  ---x     1809872   Mar 23 1993 03:36:05  c3500xl-c3h2s-mz.120-5.WC11.bin
#7  ---x          89   Mar 23 1993 03:38:19  env_vars
#
#3612672 bytes total (632832 bytes free)
#prompt#
#");

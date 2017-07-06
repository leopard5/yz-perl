#! /usr/local/bin/perl

sub GetInventoryInfo
{
	my($config) = @_;
	my(@array) = ();
	my($count) = 0;

#Mod  Ports Card Type                              Model             Serial No.
#----+-----+--------------------------------------+-----------------+-----------
# 1      2  1000BaseX (GBIC) Supervisor(active)    WS-X4014          JAB063505FT 
# 2     32  10/100BaseTX (RJ45)                    WS-X4232-RJ-XX    JAB0426050H 
# 3     32  10/100BaseTX (RJ45)                    WS-X4232-RJ-XX    JAB043004JD 
# 4     48  10/100BaseTX (RJ45)                    WS-X4148-RJ       JAE0609047N 
#
	if ($config =~ /Mod\s+Ports\s+Card\s+Type\s+Model\s+Serial No/gc)
	{
		$start = pos($config);
		$config = substr($config, $start);
		
		while ($config =~ /[\r\n] *(\d+) +(\d+) +([ \S]+) +(\S+) +(\S+)/gc)
		{
			$module = sprintf("%3d", $1);
			$ports = $2;
			$description = $3;
			$model = $4;
			$serialNumber = $5;

			# Bug 4579: Only specify port data for modules without it
			if($description !~ /^\d+ port/)
			{
				$description = "$ports port $3";
			}

			$array[$count] = "Model";
			$array[$count+1] = $module;
			$array[$count+2] = $model;
			$count += 3;

			$array[$count] = "Description";
			$array[$count+1] = $module;
			$array[$count+2] = $description;
			$count += 3;

			$array[$count] = "SerialNumber";
			$array[$count+1] = $module;
			$array[$count+2] = $serialNumber;
			$count += 3;

		}

# Two possibilities
#
#Mod MAC addresses                       Hw    Fw           Sw           Status
#--- ---------------------------------- ------ ------------ ------------ -------
#  1  0030.7b94.b1f8 to 0030.7b94.b1f9   3.1   5.1(1)       7.2(0.35)    Ok      
#  2  0004.6d46.f9f0 to 0004.6d46.fa1f   2.1   5.4(2)       7.2(0.35)    Ok      
#  3  00b0.8e80.f130 to 00b0.8e80.f15f   1.2   5.1(1)       7.2(0.35)    Ok      
#  4  0001.9749.7fa0 to 0001.9749.7fcf   1.2   5.1(1)       7.2(0.35)    Ok      
#  5  00d0.c0cc.6470 to 00d0.c0cc.649f   1.2   5.1(1)       7.2(0.35)    Ok      
#  6  0001.970b.d6e0 to 0001.970b.d70f   1.2   5.1(1)       7.2(0.35)    Ok      
#
# M MAC addresses                    Hw  Fw           Sw               Status
# --+--------------------------------+---+------------+----------------+---------
# 1 0009.b7b1.f800 to 0009.b7b1.f801 2.1 12.1(12r)EW  12.1(13)EW, EARL Ok       
# 2 0002.4bd4.f1a2 to 0002.4bd4.f1d1 1.7                               Ok       
# 3 0002.b916.8010 to 0002.b916.803f 1.7                               Ok       
# 4 0008.e3ef.1350 to 0008.e3ef.137f 3.0                               Ok       
#
#
		while($config =~ /[\r\n] *(\d+) \S+ to \S+ ([\d\.]+)[ ]+?(\S+)?[ ]*([\S, ]+)? (Ok|\S+)/gc ||
			$config =~ /(\d+) .* to [\S\d\.]+ *([\d\.]+) +?([\d\.\S]+) *([\S, ]+)? +(Ok|\S+)/gc)
		{
			$module = sprintf("%3d", $1);
			$hardware = $2;
			$firmware = $3;
			$software = $4;

			$array[$count] = "HardwareVer";
			$array[$count+1] = $module;
			$array[$count+2] = $hardware;
			$count += 3;

			if($firmware !~ /^\s*$/)
			{
				$array[$count] = "FirmwareVer";
				$array[$count+1] = $module;
				$array[$count+2] = $firmware;
				$count += 3;
			}

			if($software !~ /^\s*$/)
			{
				$array[$count] = "SoftwareVer";
				$array[$count+1] = $module;
				$array[$count+2] = $software;
				$count += 3;
			}

		}
	}
#Mod Sub-Module                  Model           Serial           Hw     Status 
#--- --------------------------- --------------- --------------- ------- -------
#  1 Policy Feature Card         WS-F6K-PFC      SAD04170HHD      1.1    Ok     
#  1 MSFC Cat6k daughterboard    WS-F6K-MSFC     SAD04190B0H      1.4    Ok     

	# More than on sub-Module can exist per card. Keep a counter
	if($config =~ /Mod +Sub-Module +Model/gc)
	{

		$start = pos($config);
		if($config =~ /\n\n/gc)
		{
			$end = pos($config);
			$subConfig = substr($config, $start, $end - $start);
		}

		$lastModule = -1;
		$i = 1;
		while($subConfig =~ /(\d+) ([\S ]+) +(\S+) +(\S+) +([\d\.]+) +(Ok|\S+)/gc)
		{
			$subModule = $1;
			$description = $2;
			$model = $3;
			$serial = $4;
			$hardwareVer = $5;

			if($subModule != $lastModule)
			{
				$i = 1; # Reset i
			}
			$subModuleID = sprintf("%3d sub Module %3d", $subModule, $i++);
			$lastModule = $subModule;

			$array[$count] = "Description";
			$array[$count+1] = $subModuleID;
			$array[$count+2] = $description;
			$count += 3;

			$array[$count] = "Model";
			$array[$count+1] = $subModuleID;
			$array[$count+2] = $model;
			$count += 3;
			
			$array[$count] = "SerialNumber";
			$array[$count+1] = $subModuleID;
			$array[$count+2] = $serial;
			$count += 3;
			
			$array[$count] = "HardwareVer";
			$array[$count+1] = $subModuleID;
			$array[$count+2] = $hardwareVer;
			$count += 3;
			

		}
	}

	# Parse show diag to obtain sub modules if data is available
	while($config =~ /Slot +(\d+):/gc)
	{
		$module = $1;
		$start = pos($config);
		if($config =~ /(Slot +\d+:)/gc){
			$end = pos($config);
			pos($config) = $end - length($1);
			$subConfig = substr($config, $start, $end - $start);
		}
		else
		{
			$subConfig = substr($config, $start);
		}

		while($subConfig =~ /PA Bay (\d+) Information:/gc)
		{
			$start = pos($subConfig);
			$subModuleID = sprintf("%3d sub Module %3d", $module, $1);

			if($subConfig =~ /(PA Bay \d+ Information:)/gc)
			{
				$end = pos($subConfig);
				pos($subConfig) = $end - length($1);
				$paConfig = substr($subConfig, $start, $end - $start);
			}
			else
			{
				$paConfig = substr($subConfig, $start);
			}
			
			if($paConfig =~ /^\s*([\S ]+)[\r\n]/)
			{
				$description = $1;
				$array[$count] = "Description";
				$array[$count+1] = $subModuleID;
				$array[$count+2] = $description;
				$count += 3;
			}

			if($paConfig =~ /Part number: (\S+)/)
			{
				$model = $1;
				$array[$count] = "Model";
				$array[$count+1] = $subModuleID;
				$array[$count+2] = $model;
				$count += 3;
			}
			
			if($paConfig =~ /Serial Number: (\S+)/i)
			{
				$serial = $1;
				$array[$count] = "SerialNumber";
				$array[$count+1] = $subModuleID;
				$array[$count+2] = $serial;
				$count += 3;
			}

			if($paConfig =~ /HW rev (\S+, board revision \S+)/i)
			{
				$hardwareVer = $1;
				$array[$count] = "HardwareVer";
				$array[$count+1] = $subModuleID;
				$array[$count+2] = $hardwareVer;
				$count += 3;
			}
			
		}

	}

	# Parse show version to get memory
	if($config =~ / +DRAM +FLASH +NVRAM/gc)
	{
		$start = pos($config);
		if($config =~ /\n\n/gc)
		{
			$end = pos($config);
			$memConfig = substr($config, $start, $end-$start);
		}
		else
		{
			$memConfig = substr($config, $start);
		}
		while($memConfig =~ /\n(\d+) +(\S+) +\S+ +\S+ +\S+ +\S+ +\S+ +\S+ +\S+ +\S+/gc)
		{
			$module = sprintf("%3d", $1);
			$memory = $2;
			
			if($memory =~ s/(\d+)K/$1/)
			{
				$memory *= 1024;
			}
			elsif($memory =~ s/(\d+)M/$1/)
			{
				$memory = $memory * 1024 * 1024;
			}
			$memory = sprintf("%.0f",$memory); 

			$array[$count] = "Memory";
			$array[$count+1] = $module;
			$array[$count+2] = $memory;
			$count += 3;
		}
	}
		
	foreach($i = 0; $i < $#array; $i++){
		$array[$i] =~ s/\s*$//g;
	}

	return @array;
}


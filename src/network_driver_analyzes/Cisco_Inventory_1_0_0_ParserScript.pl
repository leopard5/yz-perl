#! /usr/local/bin/perl

sub GetInventoryInfo
{
	my($config) = @_;
	my(@array) = ();
	my($count) = 0;

	$fullcfg = $config;
	pos($config) = 0;

	# show c7200
	if($config =~ /Network IO Interrupt Throttling:/gc)
	{
		$start = pos($config);
		if($config =~ /TLB entries /gc)
		{
			$end = pos($config);
			$subConfig = substr($config, $start, $end - $start);
		}
		else
		{
			$subConfig = substr($config, $start);
		}
	}

	# The following is for the c7200 & 3600 "show c(3600|7200)"
	$slot = $module = $description = $software = $hardware = $firmware = $memory = $serialNumber = "";
	pos($config) = 0;
	while($subConfig =~ /([\S ]+) EEPROM:/gc)
	{
	# C7200 Midplane EEPROM:
	# 	Hardware revision 2.0         	Board revision A0
	# 	Serial number     18275379  	Part number    73-3223-05
	# 	Test history      0x0         	RMA number     00-00-00
	# 	MAC=0002.4a1a.4c00, MAC Size=1024
	# 	EEPROM format version 1, Model=0x6
	# 	EEPROM contents (hex):
	# 		0x20: 01 06 02 00 01 16 DC 33 49 0C 97 05 00 02 4A 1A
	# 		0x30: 4C 00 04 00 00 00 00 00 00 05 06 50 00 00 FF 00
	# 							  	  
		$module = $1;
		$start = pos($subConfig);
		if($subConfig =~ /(\n\n|[ \S]+EEPROM:)/gc)
		{	
			$end = pos($subConfig);
			$modConfig = substr($subConfig, $start, $end - $start);
		}
		else
		{
			$modConfig = substr($subConfig, $start);
		}

		

		if($modConfig =~ /Hardware revision (\S+)\s+Board revision +(\S+)/)
		{
			$hardware = "$1 board revision $2";

			# Store hardware revision
			$array[$count] = "HardwareVer";
			$array[$count+1] = $module;
			$array[$count+2] = $hardware;
			$count += 3;
		}
		if($modConfig =~ /Serial number +(\S+)\s+Part number +(\S+)/)
		{
			$serialNumber = $1;
			$description = $2;

			# Store module + description
			$array[$count] = "Model";
			$array[$count+1] = $module;
			$array[$count+2] = $description;
			$count += 3;

			# Store serial number
			$array[$count] = "SerialNumber";
			$array[$count+1] = $module;
			$array[$count+2] = $serialNumber;
			$count += 3;
		}

		# Clear the data
		$slot = $module = $description = $software = $hardware = $firmware = $memory = $serialNumber = "";
	}

	# show diag output:: works for 7200 and 7500 platforms
	# Slot 6:
	#         EEPROM format version 1
	#         Route/Switch Processor 4, HW rev 1.01, board revision D0
	#         Serial number: 12322029  Part number: 73-1689-03
	#         Test history: 0x00        RMA number: 00-00-00
	#         Flags: cisco 7000 board; 7500 compatible
	#
	#         EEPROM contents (hex):
	#           0x20: 01 1A 01 01 00 BC 04 ED 49 06 99 03 00 00 00 00
	#           0x30: 68 00 00 01 00 00 00 00 00 00 00 00 00 00 00 00
	# Slot 31 (virtual):
	#         EEPROM format version 1
	#         Chassis Interface, HW rev 1.00, board revision B0
	#         Serial number: 03186727  Part number: 73-1306-02
	#         Test history: 0x00        RMA number: 00-00-00
	#         Flags:  unknown flags 0x7F
	#         
	#         EEPROM contents (hex):
	#           0x20: 01 10 01 00 00 30 A0 27 49 05 1A 02 00 00 00 00
	#           0x30: 58 00 00 00 FF 00 00 00 00 00 00 00 00 00 00 FF
	#
	$slot = $module = $description = $software = $hardware = $firmware = $memory = $serialNumber = "";
	pos($config) = 0;
	while($config =~ /(^|[^\S ])Slot (\d+)( \(virtual\))?:/gc)
	{
		$module = $2;
		$virtual = $3;

		$module = sprintf("slot %3d", $module);
		if($virtual ne "")
		{
			$module = sprintf("%s%s", $module, $virtual);
		}

		$start = pos($config);
		if($config =~ /([^\S ]Slot \d+:)/gc)
		{
			$end = pos($config);
			pos($config) -= length($1); # Backup config to capture next slot

			$subConfig = substr($config, $start, $end - $start);
		}
		else
		{
			$subConfig = substr($config, $start);
		}

		$subConfigOriginal = $subConfig;

		# Remove PA information from SubConfig
		if($subConfig =~ /(PA Bay \d+ Information:|[\S ]+ Slot \d+:|[\S ]+Daughter Card)/gc)
		{
			$end = pos($subConfig);
			$subConfig = substr($subConfig, 0, $end);
		}

		if ($subConfig =~ /\s*(Hardware is |DFC type is )?(.*?, \d+ ports?)/ ||
		    $subConfig =~ /(\s*)([\S ]+ Port adapter.*)/ ||
			$subConfig =~ /\s*(Hardware is |DFC type is )([\S ]+)/)
		{
			$description = $2;
			$array[$count] = "Description";
			$array[$count+1] = $module;
			$array[$count+2] = $description;
			$count += 3;
		}
        elsif ($subConfig =~ /(\d+-subslot [\S ]+ controller)/)
        {
			$description = $1;
			$array[$count] = "Description";
			$array[$count+1] = $module;
			$array[$count+2] = $description;
			$count += 3;
		}
		elsif ($subConfig =~ /^\s*(.*AS5350.*)/)
		{
			# AS5350 seems to list the module description for some modules in the first line with no "DFC/Hardware is" header.
			$description = $1;
			$array[$count] = "Description";
			$array[$count+1] = $module;
			$array[$count+2] = $description;
			$count += 3;
		}

		if($subConfig =~ /Hardware revision +(\S+)\s+Board revision +(\S+)/)
		{
			$hardware = "$1 board revision $2";
			# Store hardware revision
			$array[$count] = "HardwareVer";
			$array[$count+1] = $module;
			$array[$count+2] = $hardware;
			$count += 3;
		}
		elsif($subConfig =~ /([ \S]+), HW rev (\S+), (board revision \S+)/)
		{
			$hardware = "$2 $3";
			$description = $1;
			
			# Store description
			$array[$count] = "Description";
			$array[$count+1] = $module;
			$array[$count+2] = $description;
			$count += 3;

			# Store hardware revision
			$array[$count] = "HardwareVer";
			$array[$count+1] = $module;
			$array[$count+2] = $hardware;
			$count += 3;
		}

		# 2600 device
		# C2611 2E Mainboard Port adapter, 4 ports
		# Port adapter is analyzed 
		# Port adapter insertion time unknown
		# EEPROM contents at hardware discovery:
		# Hardware Revision        : 2.2
		# PCB Serial Number        : JAB032002R7 (2013789111)
		# Part Number              : 73-2840-12
		# RMA History              : 00
		# RMA Number               : 0-0-0-0
		# Board Revision           : A0
		# Deviation Number         : 0-0
		elsif($subConfig =~ /Hardware Revision +: (\S+)/)
		{
			$hardware = $1;
			if($subConfig =~ /Board Revision +: (\S+)/)
			{
				$hardware = sprintf("%s Board revision %s", $hardware, $1);
			}
			# Store hardware revision
			$array[$count] = "HardwareVer";
			$array[$count+1] = $module;
			$array[$count+2] = $hardware;
			$count += 3;

		}
		elsif($subConfig =~ /Board Hardware Version (\S+), Item Number (\S+),/)
		{
			$hardware = $1;
			$model = $2;
			if($subConfig =~ /Board Revision (\S+),/)
			{
				$hardware .= " board revision $1";
			}
			# Store hardware revision
			$array[$count] = "HardwareVer";
			$array[$count+1] = $module;
			$array[$count+2] = $hardware;
			$count += 3;

			# Store hardware revision
			$array[$count] = "Model";
			$array[$count+1] = $module;
			$array[$count+2] = $model;
			$count += 3;
		}
        elsif($subConfig =~ /HW rev (\S+, board revision \S+)/)
        {
            $hardware = $1;
            # Store hardware revision
            $array[$count] = "HardwareVer";
            $array[$count+1] = $module;
            $array[$count+2] = $hardware;
            $count += 3;
        }

		if($subConfig =~ /Serial [Nn]umber:? +(\S+)\s+Part number:? +(\S+)/ ||
		   $subConfig =~ /PCB Serial Number +: +([\S ]+)\s*Part Number +: +(\S+)/ ||
		   $subConfig =~ /Serial Number +: +(\S+)/ ||
		   $subConfig =~ /Serial Number +(\S+),/ )
		{
			$serialNumber = $1;
			$model = $2;

			if($subConfig =~ /FRU Part Number: *([ \S]+)/)
			{
				$model = sprintf("%s/%s", $model, $1);
			}
			if($model eq ""){
				if($subConfig =~ /Product \(FRU\) Number +: (\S+)/)
				{
					$model = $1;
				}
				if($subConfig =~ /Part Number +: (\S+)/)
				{
					$model = sprintf("%s/%s", $model, $1);
				}
			}
			if($model ne "")
			{
				# Store module + description
				$array[$count] = "Model";
				$array[$count+1] = $module;
				$array[$count+2] = $model;
				$count += 3;
			}

			# Store serial number
			$array[$count] = "SerialNumber";
			$array[$count+1] = $module;
			$array[$count+2] = $serialNumber;
			$count += 3;
		}

		# Controller Memory Size: 128 MBytes CPU SDRAM, 64 MBytes Packet SDRAM
		if($subConfig =~ /Controller Memory Size: ([\d \S]+)/ || 
           $subConfig =~ /(\d+ \S+)Bytes Total on Board SDRAM/g )
		{
			$memory = $1;
			if($memory =~ /^(\d+) K.*/)
			{
				$memory = $1;
				$memory *= 1024;
			}
			elsif($memory =~ /^(\d+) M/)
			{
				$memory = $1;
				$memory = $memory * 1024 * 1024;
			}

			$array[$count] = "Memory";
			$array[$count+1] = $module;
			$array[$count+2] = int $memory;
			$count += 3;
		}
            
        if($subConfig =~ /IOS.*Software .*?, ([ \S]+)/)
        {
            $OSVer = $1;
            $array[$count] = "SoftwareVer";
            $array[$count+1] = $module;
            $array[$count+2] = $OSVer;
            $count += 3;

        }

		# Account for 7500 VIPs with Port Adapters (PA) in bays and daughter cards on 2600s
		$subConfig = $subConfigOriginal;

		pos($subConfig) = 0;
		while($subConfig =~ /((PA Bay \d+) Information:|(\S+ Slot \d+):|([\S ]+Daughter Card)|(AIM Module in slot: \d+))/gc)
		{
			# PA Bay's are only useful in the context of the VIP that they are on
			$bayModule = $1;
			$bayModule =~ s/ *Information//; # Remove excess from previous match
			$bayModule =~ s/:$//;

			$bayModule = sprintf("%s %s", $module, $bayModule);
			
			$start = pos($subConfig);
			if($subConfig =~ /([\S ]*Slot \d+|PA Bay \d+|[\S ]+Daughter Card)/gc)
			{
				$end = pos($subConfig) - length($1);
				pos($subConfig) -= length($1); # Do not gobble up the next entry
				$bayConfig = substr($subConfig, $start, $end - $start);
			}
			else
			{
				$bayConfig = substr($subConfig, $start);
			}

			if($bayModule =~ /(AIM Module)/)
			{
				$description = $1;
				$array[$count] = "Description";
				$array[$count+1] = $bayModule;
				$array[$count+2] = $description;
				$count += 3;
			}
			elsif($bayConfig =~ /\s*(.*?, \d+ ports?)/)
			{
				$description = $1;
				$array[$count] = "Description";
				$array[$count+1] = $bayModule;
				$array[$count+2] = $description;
				$count += 3;
			}
			elsif($bayConfig =~ /\s*(.*? card)/)
			{
				$description = $1;
				$array[$count] = "Description";
				$array[$count+1] = $bayModule;
				$array[$count+2] = $description;
				$count += 3;
			}
			elsif($bayConfig =~ /^\s+([\S ]+)/)
			{
				$description = $1;
				if($description =~ /Hardware Revision/)
				{
					if($bayModule =~ /Daughter Card/)
					{
						$description = "Daughter Card";
					}
				}
				$array[$count] = "Description";
				$array[$count+1] = $bayModule;
				$array[$count+2] = $description;
				$count += 3;
			}

			if($bayConfig =~ /HW rev (\S+), Board revision (\S+)/ ||
			   $bayConfig =~ /Hardware revision (\S+)\s+Board revision (\S+)/)
			{
				$hardware = "$1 board revision $2";
				$array[$count] = "HardwareVer";
				$array[$count+1] = $bayModule;
				$array[$count+2] = $hardware;
				$count += 3;
			}
			elsif($bayConfig =~ /Hardware Revision +: (\S+)/)
			{
				$hardware = $1;
				if($bayConfig =~ /Board Revision +: (\S+)/)
				{
					$hardware .= " board revision $1";
				}
				$array[$count] = "HardwareVer";
				$array[$count+1] = $bayModule;
				$array[$count+2] = $hardware;
				$count += 3;
			}
				

			if($bayConfig =~ /Serial number:?\s+(\S+)\s+Part number:?\s+(\S+)/)
			{
				$serialNumber = $1;
				$model = $2;

				$array[$count] =  "SerialNumber";
				$array[$count+1] = $bayModule;
				$array[$count+2] = $serialNumber;
				$count += 3;

				$array[$count] = "Model";
				$array[$count+1] = $bayModule;
				$array[$count+2] = $model;
				$count += 3;
			}
			elsif ($bayConfig =~ /PCB Serial Number +: (\S+)/)
			{
				$serialNumber = $1;
				$array[$count] =  "SerialNumber";
				$array[$count+1] = $bayModule;
				$array[$count+2] = $serialNumber;
				$count += 3;
				
				if($bayConfig =~ /Part Number +: ([\S ]+)/)
				{
					$model = $1;
					if($bayConfig =~ /Product \(FRU\) Number +: (\S+)/)
					{
						$model = sprintf("%s/%s", $1, $model);
					}
					$array[$count] = "Model";
					$array[$count+1] = $bayModule;
					$array[$count+2] = $model;
					$count += 3;
				}
			}

		}

        # Check for 7600 inventory
        # subslot 4/0: SPA-2XOC3-POS (0x43F), status: ok
        # subslot 6/1: SPA-4XOC3-ATM (0x3E1), status: ok
        if($subConfig =~ /subslot/){
            pos($subConfig) = 0;
            while($subConfig =~ /\n +(subslot +\d+\/\d+): (\S+) +\S+, status: \S+/gc)
            {
                $subSlot = $1;
                $model = $2;

                $array[$count] = "Model";
                $array[$count+1] = $subSlot;
                $array[$count+2] = $model;
                $count += 3;
            }
        }

		# Reset for the next pass
		$slot = $module = $description = $software = $hardware = $firmware = $memory = $serialNumber = "";
	}

	# From show version on 3550
	# Base ethernet MAC Address: 00:0A:8A:9A:2A:00
	# Motherboard assembly number: 73-5700-08
	# Power supply part number: 34-0966-02
	# Motherboard serial number: CAT06300B3Q
	# Power supply serial number: DAB06280GAW
	# Model revision number: E0
	# Motherboard revision number: D0
	# Model number: WS-C3550-24-SMI
	# System serial number: CAT0630X14A
	pos($config) = 0;
	if($config =~ /Power supply part number( +)?: +(\S+)/)
	{
		$module = "Power supply";
		$model = $2;
		
		$array[$count] = "Model";
		$array[$count+1] = $module;
		$array[$count+2] = $model;
		$count += 3;
	
		if($config =~ /Power supply serial number( +)?: +(\S+)/)
		{
			$module = "Power supply";
			$serialNumber = $2;

			if($serialNumber !~ /NONE/i)
			{
				$array[$count] = "SerialNumber";
				$array[$count+1] = $module;
				$array[$count+2] = $serialNumber;
				$count += 3;
			}
		}
	} # 3550 end

	pos($config) = 0;
	if ($config =~ /Top Assembly Part Number +: +(\S+)/)
	{
		$module = "Top Assembly";
		$model = $1;
		$array[$count] = "Model";
		$array[$count+1] = $module;
		$array[$count+2] = $model;
		$count += 3;
	}
    
	# From a 3750 - show version
	#  Base ethernet MAC Address       : 00:09:43:A7:F2:00
	#  Motherboard assembly number     : 73-7056-05
	#  Motherboard serial number       : CSJ0638004U
	#  Motherboard revision number     : 05
	#  Model number                    : 73-7056-05
	#
	#
	#  Switch   Ports  Model              SW Version              SW Image
	#  ------   -----  -----              ----------              ----------
	#       1   28     WS-C3750G-24TS     12.1(0.0.709)EA1        C3750-I5-M
	#       *    8   52     WS-C3750-48TS      12.1(0.0.709)EA1        C3750-I5-M
	#
	#
	#       Switch 01
	#       ---------
	#
	#       Switch Uptime                   : 2 days, 11 hours, 17 minutes
	#       Base ethernet MAC Address       : 00:0B:46:2E:35:80
	#       Motherboard assembly number     : 73-7058-04
	#       Power supply part number        : 341-0045-01
	#       Motherboard serial number       : CSJ0640010L
	#       Model number                    : WS-C3750-24TS-SMI
	#       System serial number            : CSJ0642U00A

	pos($config) = 0;
	if($config =~ /Switch +Ports +Model +SW Version +SW Image/gc)
	{
		$start = pos($config);
		# Break the config into two sections ... Base unit and additional units
		$baseConfig = substr($config, 0, $start);
		$config = substr($config, $start);
		
		$module = "";
		if($baseConfig =~ /Motherboard assembly number *: (\S+)/)
		{
			$module = "Motherboard";
			$model = $1;

			$array[$count] = "Model";
			$array[$count+1] = $module;
			$array[$count+2] = $model;
			$count+=3;
		}
		if($module && $baseConfig =~ /Motherboard serial number *: (\S+)/)
		{
			$serialNumber = $1;
			
			$array[$count] = "SerialNumber";
			$array[$count+1] = $module;
			$array[$count+2] = $serialNumber;
			$count+=3;
		}
		if($module && $baseConfig =~ /Motherboard revision number *: (\S+)/)
		{
			$hardwareVer = $1;
			
			$array[$count] = "HardwareVer";
			$array[$count+1] = $module;
			$array[$count+2] = $hardwareVer;
			$count+=3;
		}
		
		# Parse out the switch, ports, model and sw versions
		#       1   28     WS-C3750G-24TS     12.1(0.0.709)EA1        C3750-I5-M
		#  *    8   52     WS-C3750-48TS      12.1(0.0.709)EA1        C3750-I5-M
		while($config =~ /\*? *(\d+) +\d+ +(\S+) +(\S+) +\S+[\r\n]/gc)
		{
			$unit = sprintf("Switch %3d", $1);
			$model = $2;
			$softwareVer = $3;

			# Ignore model here, it's explained in further detail in the following section

			$array[$count] = "SoftwareVer";
			$array[$count+1] = $unit;
			$array[$count+2] = $softwareVer;
			$count += 3;

		}
			
		pos($config) = 0;
		
		# Parse the switch units next
		while($config =~ /Switch +(\d+)/gc)
		{
			$member = $1;
			$member =~ s/^0+//g;
			$module = sprintf("Switch %3d", $member);

			$start = pos($config);
			if($config =~ /(\s*Switch +\d+)/)
			{
				$end = pos($config) - length($1);
				$subConfig = substr($config, $start, $end - $start);
			}
			else
			{
				$subConfig = substr($config, $start);
			}

			if($subConfig =~ /Motherboard assembly number *: (\S+)/)
			{
				$model = $1;
				$array[$count] = "Model";
				$array[$count+1] = sprintf("%s Motherboard", $module);
				$array[$count+2] = $model;
				$count += 3;
			}
			if($subConfig =~ /Power supply part number *: (\S+)/)
			{
				$model = $1;
				$array[$count] = "Model";
				$array[$count+1] = sprintf("%s Power supply", $module);
				$array[$count+2] = $model;
				$count += 3;
			}
			if($subConfig =~ /Motherboard serial number *: (\S+)/)
			{
				$serialNumber = $1;
				$array[$count] = "SerialNumber";
				$array[$count+1] = sprintf("%s Motherboard", $module);
				$array[$count+2] = $serialNumber;
				$count += 3;
			}
			if($subConfig =~ /Model number *: (\S+)/)
			{
				$model = $1;
				$array[$count] = "Model";
				$array[$count+1] = $module;
				$array[$count+2] = $model;
				$count += 3;

			}
			if($subConfig =~ /System serial number *: (\S+)/)
			{
				$serialNumber = $1;
				$array[$count] = "SerialNumber";
				$array[$count+1] = $module;
				$array[$count+2] = $serialNumber;
				$count += 3;
			}

			while ($config =~ /\#session $member\n([\S\s\n ]+?)\#exit/gc)
			{
				$subConfig = $1;

				if($subConfig =~ /isco [\S ]+ processor [\S ]+ with (\S+)\/[\S]+ bytes of memory/ ||
				   $subConfig =~ /isco [\S ]+ processor [\S ]+ with (\S+) bytes of memory/ ||
				   $subConfig =~ /isco [\S ]+ processor with (\S+)\/[\S]+ bytes of memory/  ||
				   $subConfig =~ /isco [\S ]+ processor with (\S+) bytes of memory/ ||
				   $subConfig =~ /isco [\S ]+ with (\S+)\/[\S]+ bytes of memory/)
			        {
					$memory = $1;
					if($memory =~ s/(\d+)K/$1/)
					{
						$memory *= 1024;
				        }
				        elsif($memory =~ s/(\d+)M/$1/)
				        {
				                $memory = $memory * 1024 * 1024;
					}
					$array[$count] = "Memory";
					$array[$count+1] = $module;
					$array[$count+2] = int $memory;
					$count += 3;

				}

				if($subConfig =~ /Hardware Board Revision Number +: +(\S+)/)
				{
					$hardwarever = $1;
					$array[$count] = "HardwareVer";
					$array[$count+1] = $module;
					$array[$count+2] = $hardwarever;
					$count += 3;
				}
			}

		}

	}
	# From GSR: show gsr chassis-info
	# Backplane NVRAM [version 0x20] Contents -
	# Chassis: type 12012 Fab Ver: 1
	# Chassis S/N: ZQ24CS3WT86MGVHL
	# PCA: 800-3015-1 rev: A0 dev: 257 HW ver: 1.0
	# Backplane S/N: A109EXPR75FUNYJK
	pos($config) = 0;
	if($config =~ /Chassis: type (\S+) Fab Ver: (\d+)/)
	{
		$module = "Chassis";
		$model = $1;
		$hardware = $2;

		$array[$count] = "Model";
		$array[$count+1] = $module;
		$array[$count+2] = $model;
		$count += 3;

		$array[$count] = "HardwareVer";
		$array[$count+1] = $module;
		$array[$count+2] = $hardware;
		$count += 3;

		if($config =~ /Chassis S\/N: (\S+)/){
			$module = "Chassis";
			$serialNumber = $1;

			$array[$count] = "SerialNumber";
			$array[$count+1] = $module;
			$array[$count+2] = $serialNumber;
			$count += 3;
		}

		if($config =~ /(PCA): (\S+) rev: (\S+) dev: \S+ HW ver: (\S+)/)
		{
			$module = $1;
			$model = $2;
			$hardware = "$4 revision $3";

			$array[$count] = "Model";
			$array[$count+1] = $module;
			$array[$count+2] = $model;
			$count += 3;

			$array[$count] = "HardwareVer";
			$array[$count+1] = $module;
			$array[$count+2] = $hardware;
			$count += 3;
		}
		
		if($config =~ /(Backplane) S\/N: (\S+)/)
		{
			$module = $1;
			$serialNumber = $2;

			$array[$count] = "SerialNumber";
			$array[$count+1] = $module;
			$array[$count+2] = $serialNumber;
			$count += 3;
		}
		
		# Continue and parse the GSR slot information
		pos($config) = 0;
		while($config =~ /SLOT (\d+) +[\S ]+: *([\S ]+)/gc)
		{
			$module = sprintf("slot %3d", $1);
			$description = $2;
			$start = pos($config);
			if($config =~ /(SLOT \d+)/gc)
			{
				$end = pos($config) - length($1);
				pos($config) -= length($1); # Compensate for passing the next slot
				$subConfig = substr($config, $start, $end - $start);
			}
			else
			{
				$subConfig = substr($config, $start);
			}
			
			# Store description learnt above
			$array[$count] = "Description";
			$array[$count+1] = $module;
			$array[$count+2] = $description;
			$count += 3;

			# Each section may have a MAIN, PCA, MBUS, DIAG, FRU section.
			# MAIN, PCA, MBUS and FRU contain relevant information
			@subSections = qw (MAIN PCA MBUS FRU);
			foreach $section (@subSections)
			{
				pos($subConfig) = 0;

				if($subConfig =~ /$section:/gc)
				{
					$start = pos($subConfig);

					if($subConfig =~ /(\s*(MAIN|PCA|MBUS|FRU|EEPROM):|[ \S]*Engine)/gc)
					{
						pos($subConfig) -= length($1);
						$end = pos($subConfig);
						$subSectionConfig = substr($subConfig, $start, $end - $start);
					}
					else
					{
						$subSectionConfig = substr($subConfig, $start);
					}
					
					$subModule = sprintf("%s %s", $module, $section);
					
					if($section eq "MAIN" && $subSectionConfig =~ /type \S+, +(\S+) rev (\S+)/)
					{
						$model = $1;
						$hardware = "revision $2";

						$array[$count] = "Model";
						$array[$count+1] = $subModule;
						$array[$count+2] = $model;
						$count += 3;

						$array[$count] = "HardwareVer";
						$array[$count+1] = $subModule;
						$array[$count+2] = $hardware;
						$count += 3;
					}
					elsif($section eq "PCA"){
						if($subSectionConfig =~ /(\S+) +rev (\S+) ver (\S+)/)
						{
							$model = $1;
							$hardware = "revision $2 version $3";
						
							$array[$count] = "Model";
							$array[$count+1] = $subModule;
							$array[$count+2] = $model;
							$count += 3;

							$array[$count] = "HardwareVer";
							$array[$count+1] = $subModule;
							$array[$count+2] = $hardware;
							$count += 3;
						}
						if($subSectionConfig =~ /S\/N (\S+)/)
						{
							$serialNumber = $1;

							$array[$count] = "SerialNumber";
							$array[$count+1] = $subModule;
							$array[$count+2] = $serialNumber;
							$count += 3;
						}

					}
					elsif($section eq "MBUS")
					{
						if($subSectionConfig =~ /MBUS Agent \S+ +(\S+) rev (\S+) dev \S+/)
						{
							$model = $1;
							$hardware = "revision $2";

							$array[$count] = "Model";
							$array[$count+1] = $subModule;
							$array[$count+2] = $model;
							$count += 3;

							$array[$count] = "HardwareVer";
							$array[$count+1] = $subModule;
							$array[$count+2] = $hardware;
							$count += 3;
						}
						if($subSectionConfig =~ /S\/N (\S+)/)
						{
							$serialNumber = $1;

							$array[$count] = "SerialNumber";
							$array[$count+1] = $subModule;
							$array[$count+2] = $serialNumber;
							$count += 3;
						}
					}
					elsif($section eq "FRU")
					{
						pos($subSectionConfig) = 0;
						while($subSectionConfig =~ /(Linecard\/Module|Route Memory|Packet Memory): *(\S+)/gc)
						{
							$description = $1;
							$model = $2;
							$FRU_model = sprintf("%s %s", $subModule, $description);

							$array[$count] = "Model";
							$array[$count+1] = $FRU_model;
							$array[$count+2] = $model;
							$count += 3;
						}
					} # End elsif (FRU)
				} # End if(subConfig =~ /$section/

			} # End foreach (@subSection)

			# Obtain memory for line cards
			pos($subConfig) = 0;
			$memory = 0;
			while($subConfig =~ /(ToFab|FrFab) SDRAM size: (\d+) bytes/gc)
			{
				$memory += int $2;
			}
			if($memory != 0)
			{
				$array[$count] = "Memory";
				$array[$count+1] = $module;
				$array[$count+2] = int $memory;
				$count += 3;
			}
			
		} # End while($config =~ /SLOT... GSR section
	} # if($config =~ /Chassis: type (\S+)

	# cat8540 ; cmd=show hardware detail
	pos($config) = 0;
	if($config =~ /slot: +\d+\/\S+/)
	{
		while($config =~ /slot: +(\d+\/\S+) +Controller-Type *: ([\S ]+)/gc)
		{
			$module = $1;
			$description = $2;
			$start = pos($config);

			if($config =~ /(\s*slot:)/gc)
			{
				$end = pos($config) - length($1);
				pos($config) -= length($1);
				$subConfig = substr($config, $start, $end - $start);
			}
			else
			{
				$subConfig = substr($config, $start);
			}

			if($subConfig =~ /(Part Number: \S+)/)
			{
				$array[$count] = "Model";
				$array[$count+1] = $module;
				$array[$count+2] = $description . " $1";
				$count += 3;
			}
			else
			{
				$array[$count] = "Model";
				$array[$count+1] = $module;
				$array[$count+2] = $description;
				$count += 3;
			}
				
			if ($subConfig =~ /Serial Number: +(\S+)/)
			{	
				$array[$count] = "SerialNumber";
				$array[$count+1] = $module;
				$array[$count+2] = $1;
				$count += 3;
			}

			if ($subConfig =~ /H\/W Version: +(\S+)/)
			{	
				$array[$count] = "HardwareVer";
				$array[$count+1] = $module;
				$array[$count+2] = $1;
				$count += 3;
			}

			pos($subConfig) = 0;
			while($subConfig =~ /(((Optical .*|TCAM) Daughter Card) .*EEPROM):/gc)
			{
				$description = $1;
				$subModule = "$module - $2";

				$start = pos($subConfig);
				if($subConfig =~ /(\n\n|(Optical .*|TCAM))/gc){
					$end = pos($subConfig) - length($1);
					$daughterConfig = substr($subConfig, $start, $end - $start);
				}
				else
				{
					$daughterConfig = substr($subConfig, $start);
				}
				
				if($daughterConfig =~ /(Part Number: \S+)/)
				{
					$array[$count] = "Model";
					$array[$count+1] = $subModule;
					$array[$count+2] = $description . " $1";
					$count += 3;
				}
				else
				{
					$array[$count] = "Model";
					$array[$count+1] = $subModule;
					$array[$count+2] = $description;
					$count += 3;
				}

				if($daughterConfig =~ /Serial Number: +(\S+)/)
				{	
					$array[$count] = "SerialNumber";
					$array[$count+1] = $subModule;
					$array[$count+2] = $1;
					$count += 3;
				}
				if($daughterConfig =~ /HW Rever: +(\S+)/)
				{
					$array[$count] = "HardwareVer";
					$array[$count+1] = $subModule;
					$array[$count+2] = $1;
					$count += 3;
				}

			} # End: while($subConfig =~ /((Optical .*|TCAM) Daughter .*EEPROM):/gc)

		} # End: while($config =~ /slot +(\d+\/\S+) +Controller-Type *: ([\S ]+)/gc)

		# Look for Backplane EEPROM
		
		# Look for Power Supply information
		if($config =~ /Power Supply:/gc){
			$start = pos($config);
			$subConfig = substr($config, $start);

			# Slot Part No.         Rev  Serial No.  RMA No.     Hw Vrs  Power Consumption
			# ---- ---------------- ---- ----------- ----------- ------- -----------------
			# 0          34-0918-02 B0   ACP03431102 00-00-00-00   2.1             2746 cA
			# 1          34-0918-02 B0   ACP03421384 00-00-00-00   2.1             2746 cA
			while($subConfig =~ /(\d+) +(\S+) +(\S+) +(\S+) +\S+ +(\S+)/gc)
			{
				$module = $1;
				$description = "Power Supply - Part Number $2";
				$rev = $3;
				$serialNumber = $4;
				$HardwareVer = $5;

				$array[$count] = "Model";
				$array[$count+1] = $module;
				$array[$count+2] = $description;
				$count += 3;

				$array[$count] = "HardwareVer";
				$array[$count+1] = $module;
				$array[$count+2] = "$HardwareVer revision $rev";
				$count += 3;

				$array[$count] = "SerialNumber";
				$array[$count+1] = $module;
				$array[$count+2] = $serialNumber;
				$count += 3;
			}
		} # End: Power supply section
	}elsif($config =~ /Slot +\d+\/\d+:/) {
	# cat8510 ; cmd=show hardware detail
		while($config =~ /Slot +(\d+\/\d+):\s*Ctrlr-Type *: ([\S ]+) +Part No +: (\S+)/gc)
		{
			# Slot 0/1:
			# Ctrlr-Type : CE-T1 PAM Part No : 73-3914-01
			# Revision : C0 Ser. No : 21735909
			# Mfg Date : Oct 12 00 Rma No : 00-00-00
			# Hardware Version : 5.1 Tst 0 : EEP 2

			$module = $1;
			$description = $2;
			$model = $3;
			$description =~ s/ +/ /g;
			$start = pos($config);

			if($config =~ /(\s*Slot )/gc)
			{
				$end = pos($config) - length($1);
				pos($config) -= length($1);
				$subConfig = substr($config, $start, $end - $start);
			}
			else
			{
				$subConfig = substr($config, $start);
			}

			$array[$count] = "Model";
			$array[$count+1] = $module;
			$array[$count+2] = $model;
			$count += 3;
				
			$array[$count] = "Description";
			$array[$count+1] = $module;
			$array[$count+2] = $description;
			$count += 3;
				
			if ($subConfig =~ /Ser\. No +: +(\S+)/)
			{	
				$array[$count] = "SerialNumber";
				$array[$count+1] = $module;
				$array[$count+2] = $1;
				$count += 3;
			}

			if ($subConfig =~ /Hardware Version +: +(\S+)/)
			{	
				$array[$count] = "HardwareVer";
				$array[$count+1] = $module;
				$array[$count+2] = $1;
				$count += 3;
			}

		} 

		# Look for Backplane EEPROM
		if($config =~ /(\S+ Backplane EEPROM)/gc)
		{
			$module = $1;
			while($config =~ /(\S+) +(\d+) +(\S+) +\S+ +\d+ +\d+ +\S+ +[\S ]+\n/gc)
			{
				$model = $1;
				$hardwareVer = $2;
				$serialNum = $3;

				$array[$count] = "Model";
				$array[$count+1] = $module;
				$array[$count+2] = $model;
				$count += 3;

				$array[$count] = "HardwareVer";
				$array[$count+1] = $module;
				$array[$count+2] = $hardwareVer;
				$count += 3;

				$array[$count] = "SerialNumber";
				$array[$count+1] = $module;
				$array[$count+2] = $serialNum;
				$count += 3;
			}

		}
		
	} # End: elsif($config =~ /Slot +\d+\/\d+:/) {
	# Cisco 4948 - show module
	# Mod Ports Card Type                              Model              Serial No.
	# ---+-----+--------------------------------------+------------------+-----------
	#  1    48  1000BaseX (SFP) Supervisor             WS-C4948           FOX082406TU 

	## Code added to weed out duplicates
	
	elsif ($config =~ /Mod Ports Card Type +Model +Serial No/gc)
	{
		while($config =~ /\n *(\d+) +(\d+) +([\S ]+?) {2,}(\S+) +(\S+)/gc)
		{
			$modulenum = $1;
			$module = sprintf("slot %3d", $modulenum);
			$description = "$2 port $3";
			$model = $4;
			$serialNum = $5;

			$found = 0;
			for(my $i=0;$i<$#array;$i++) {
				if (($array[$i] eq "Model") && ($array[$i+1] eq $module)) {
					$found = 1;
				}
			}
			if ($found == 0) {
				$array[$count] = "Model";
				$array[$count+1] = $module;
				$array[$count+2] = $model;
				$count += 3;
			}

			$found = 0;
			for(my $i=0;$i<$#array;$i++) {
				if (($array[$i] eq "Description") && ($array[$i+1] eq $module)) {
					$found = 1;
				}
			}
			if ($found == 0) {
				$array[$count] = "Description";
				$array[$count+1] = $module;
				$array[$count+2] = $description;
				$count += 3;
			}

			$found = 0;
			for(my $i=0;$i<$#array;$i++) {
				if (($array[$i] eq "SerialNumber") && ($array[$i+1] eq $module)) {
					$found = 1;
				}
			}
			if ($found == 0) {
				$array[$count] = "SerialNumber";
				$array[$count+1] = $module;
				$array[$count+2] = $serialNum;
				$count += 3;
			}

			 if ($fullcfg =~ /\n *$modulenum +[0-9a-fA-F]+\.[0-9a-fA-F]+\.[0-9a-fA-F]+\.[0-9a-fA-F]+\.[0-9a-fA-F]+ +\S+ +(\S+) +(\S+)/)
			{
				$hardwarever = $1;
				$softwarever = $2;

				$found = 0;
				for(my $i=0;$i<$#array;$i++) {
					if (($array[$i] eq "SoftwareVer") && ($array[$i+1] eq $module)) {
						$found = 1;
					}
				}
				if ($found == 0) {
					$array[$count] = "SoftwareVer";
					$array[$count+1] = $module;
					$array[$count+2] = $softwarever;
					$count += 3;
				}

				$found = 0;
				for(my $i=0;$i<$#array;$i++) {
					if (($array[$i] eq "HardwareVer") && ($array[$i+1] eq $module)) {
						$found = 1;
					}
				}
				if ($found == 0) {
					$array[$count] = "HardwareVer";
					$array[$count+1] = $module;
					$array[$count+2] = $hardwarever;
					$count += 3;
				}
			}

		}
	}

	return @array;
}

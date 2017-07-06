#! /usr/local/bin/perl

sub GetInventoryInfo
{
	my($config) = @_;
	my(@array) = ();
	my($count) = 0;

	my $module = 0;
	
#	Application and Content Networking System Software (ACNS)
#Copyright (c) 1999-2004 by Cisco Systems, Inc.
#Application and Content Networking System Software Release 5.3.3 (build b8 Jun 29 2005)
#Version: ce7326-5.3.3

#Compiled 16:08:04 Jun 29 2005 by cnbuild
#Compile Time Options: PP SS

#System was restarted on Mon Sep 11 22:35:45 2006.
#The system has been up for 4 weeks, 22 hours, 1 minute, 47 seconds.

#CPU 0 is GenuineIntel Intel(R) Xeon(TM) CPU 3.20GHz (rev 4) running at 3200MHz.
#CPU 1 is GenuineIntel Intel(R) Xeon(TM) CPU 3.20GHz (rev 4) running at 3200MHz.
#Total 2 CPUs.
#3392 Mbytes of Physical memory.
#1 CD ROM drive (CD-224E)
#2 GigabitEthernet interfaces
#1 Console interface
#2 USB interfaces [Not supported in this version of software]

#Manufactured As: WAE-7326-K9  [-[8840C5X]-]

#BIOS Information:
#Vendor                             : IBM
#Version                            : -[KPEC27DUS-1.06]-
#Rel. Date                          : 02/24/2005

#  Cookie info:
#    SerialNumber: KQARF5B
#    SerialNumber (raw): 75 81 65 82 70 53 66 0 0 0 0
  #  TestDate: 9-12-2005
 #   ExtModel: CE7326
 #   ModelNum (raw): 55 0 0 0 0
#    HWVersion: 1
#    PartNumber: 53 54 55 56 57
#    BoardRevision: 1
#    ChipRev: 1
#    VendID: 0
#    CookieVer: 2
#    Chksum: 0xfbe7

#This command provides information on direct attached SCSI storage arrays only.

#No valid storage-array is detected on this device.
#Check 'show disks details' output for additional info.

#List of all disk drives:
#disk00: Normal          (h00 c00 i00 l00 - Int DAS-SCSI)  140009MB(136.7GB)
#        disk00/04: PHYS-FS      122918MB(120.0GB) mounted internally
#        disk00/04: CDNFS        122918MB(120.0GB) mounted internally
#        System use:              13113MB( 12.8GB)
#        FREE:                        0MB(  0.0GB)
#disk01: Normal          (h00 c00 i01 l00 - Int DAS-SCSI)  140011MB(136.7GB)
#        disk01/00: PHYS-FS      135630MB(132.5GB) mounted internally
#        disk01/00: CDNFS         95853MB( 93.6GB) mounted internally
#        disk01/00: MEDIAFS       39776MB( 38.8GB) mounted internally
#        FREE:                        0MB(  0.0GB)
#disk02: Normal          (h00 c00 i02 l00 - Int DAS-SCSI)  140011MB(136.7GB)
#        disk02/00: PHYS-FS        6350MB(  6.2GB) mounted internally
#        disk02/00: MEDIAFS        6350MB(  6.2GB) mounted internally
#        disk02/01: CFS           65535MB( 64.0GB)
#        FREE:                    67916MB( 66.3GB)
#disk03: Normal          (h00 c00 i03 l00 - Int DAS-SCSI)  140011MB(136.7GB)
#        disk03/00: SYSFS         54692MB( 53.4GB) mounted at /local1
#        disk03/01: CFS           65535MB( 64.0GB)
#       FREE:                    19782MB( 19.3GB)
#disk04: Not present or not responding
#disk05: Not present or not responding
#No NAS share is attached to this device.

	#disk00: Normal          (h00 c00 i00 l00 - Int DAS-SCSI)  140009MB(136.7GB)
	while ($config =~  /(disk\d+):.*?\((.*?)\s\-\s(.*?)\)\s+(.*?)\n/sg)
	{
		$module = $1;
		$description = $4;
		$model = $3;
		$serialNumber = $2;


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

	#CPU 0 is GenuineIntel Intel(R) Xeon(TM) CPU 3.20GHz (rev 4) running at 3200MHz.
	while ($config =~  /(CPU \d+) is (.*?\))(.*?rev.*?\)).*?\n/sg)
	{
		$module = $1;
		$description = $2;
		$model = $3;
		$serialNumber = "";

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
	return @array;
}


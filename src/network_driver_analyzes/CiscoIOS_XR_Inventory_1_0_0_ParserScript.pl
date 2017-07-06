#! /usr/local/bin/perl

sub GetInventoryInfo
{
	my($config) = @_;
	my(@array) = ();
	my($count) = 0;

#NAME: "0/0/SP", DESCR: "Cisco CRS-1 Series Modular Services Card"
#PID: CRS-MSC           , VID: V03, SN: SAD093707GV

#NAME: "0/0/CPU0", DESCR: "Cisco CRS-1 Series 16xOC48/STM16 POS/DPT Interface Module"
#PID: 16OC48-POS/DPT    , VID: V02, SN: SAD09230715

#NAME: "0/4/SP", DESCR: "Cisco CRS-1 Series Modular Services Card"
#PID: CRS-MSC           , VID: V03, SN: SAD093702E8

#NAME: "0/4/CPU0", DESCR: "Cisco CRS-1 Series 8x10GbE Interface Module"
#PID: 8-10GBE           , VID: V04, SN: SAD093301LF

#NAME: "0/7/SP", DESCR: "Cisco CRS-1 Series Modular Services Card"
#PID: CRS-MSC           , VID: V03, SN: SAD093702DF

#NAME: "0/7/CPU0", DESCR: "jacket"
#PID: CRS1-SIP-800      , VID: V01, SN: SAD0941053M

#NAME: "0/7/0", DESCR: "8-port Gigabit Ethernet Shared Port Adapter "
#PID: SPA-8X1GE         , VID: V01, SN: SAD09370208

#NAME: "0/7/5", DESCR: "1-Port OC192/STM64 POS/RPR XFP Optics "
#PID: SPA-OC192POS-XFP  , VID: V02, SN: JAB094102JQ

#NAME: "0/RP0/CPU0", DESCR: "Cisco CRS-1 Series 8 Slots Route Processor"
#PID: CRS-8-RP          , VID: V01, SN: SAD093507J1

#NAME: "0/RP1/CPU0", DESCR: "Cisco CRS-1 Series 8 Slots Route Processor"
#PID: CRS-8-RP          , VID: V01, SN: SAD093507JD

#NAME: "0/0/0/0", DESCR: "GE SX"
#PID: SFP-GE-S            , VID: V01 , SN: FNS11510KMF



	my $module = 0;
	while ($config =~  /.*?NAME:\s*\"([\S ]+?)\".*?DESCR:\s+\"(.*?)\".*?PID:\s*(\S*?)\s*,\s*VID:\s*(\S+),.*?SN:\s*(\S*?)\n/gs)
	{
		$module = $1;
		$description = $2;
		$model = $3;
		$serialNumber = $5;

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

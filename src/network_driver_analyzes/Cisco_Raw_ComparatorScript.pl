#! /usr/local/bin/perl

sub compare
{
	my($data, $compareData, $maskWLCCPPwd,$logLevel) = @_;

	$data        =~ s/^\n*![\S ]*[\r\n]*//g;
	$compareData =~ s/^\n*![\S ]*[\r\n]*//g;

	$data        =~ s/uptime is .*\n//;
	$compareData =~ s/uptime is .*\n//;

	$data        =~ s/! Last configuration change at .*\n(!\n)?//;
	$compareData =~ s/! Last configuration change at .*\n(!\n)?//;

	$data        =~ s/! No configuration change since last restart.*\n(!\n)?//;
	$compareData =~ s/! No configuration change since last restart.*\n(!\n)?//;

	$data        =~ s/! NVRAM config last updated .*\n(!\n)?//;
	$compareData =~ s/! NVRAM config last updated .*\n(!\n)?//;

	$data        =~ s/ntp clock-period \S+\n//;
	$compareData =~ s/ntp clock-period \S+\n//;

	$data        =~ s/System returned to ROM by reload at .*\n(!\n)?//;
	$compareData =~ s/System returned to ROM by reload at .*\n(!\n)?//;

	$data        =~ s/System restarted at .*\n//;
	$compareData =~ s/System restarted at .*\n//;

        # Bug 160818
        $data        =~ s/mac-address-table secure [\S ]+\n//g;
        $compareData =~ s/mac-address-table secure [\S ]+\n//g;

	# strip off final \n in comparisons - see if that solves some problems.
	$data        =~ s/\nend\n/\nend/;
	$compareData =~ s/\nend\n/\nend/;

	# Aironet 1100 IOS device
	$data        =~ s/encryption key (\d+) size (\S+) (\d+) (\S+) ([\S]+)*/encryption key $1 size $2 $3 xxx $5/g;
	$compareData =~ s/encryption key (\d+) size (\S+) (\d+) (\S+) ([\S]+)*/encryption key $1 size $2 $3 xxx $5/g;

	# Aironet 1200 IOS device
	$data        =~ s/user \S+ nthash .*//g;
	$compareData =~ s/user \S+ nthash .*//g;

	if ($maskWLCCPPwd eq "true")
	{
		$data        =~ s/wlccp ap username (\S+) password 7 (\S+)/wlccp ap username $1 password 7 xxx/g;
		$compareData =~ s/wlccp ap username (\S+) password 7 (\S+)/wlccp ap username $1 password 7 xxx/g;
	}

    # Bug 9592
    # Check for special crypto key startup/running differents
    if($data =~ /crypto (ca|pki) certificate/){
        
        # certificate self-signed 01 nvram:\S+.cer
        $data        =~ s/\s*certificate (self-signed |ca )?\S+ nvram:\S+.cer\s*//g;
        $compareData =~ s/\s*certificate (self-signed |ca )?\S+ nvram:\S+.cer\s*//g;

        # mask key values from certificate 
        $data        =~ s/\s*certificate (self-signed |ca )?\S+(\s*([A-F\d ]+)\s*)+quit\s*//g;
        $compareData =~ s/\s*certificate (self-signed |ca )?\S+(\s*([A-F\d ]+)\s*)+quit\s*//g;

        # mask key values from certificate 
        $data        =~ s/\s*certificate \S+(\s*([A-F\d ]+)\s*)+quit\s*//g;
        $compareData =~ s/\s*certificate \S+(\s*([A-F\d ]+)\s*)+quit\s*//g;


    }

    # Bug 10007: ip host commands are arbitrarily output
    if($data =~ /ip host/ && $compareData =~ /ip host/){
        while($data =~ /ip host ([\S ]+)/){
            $host = $1;
            $compareData =~ s/ip host $host//;
            $data =~ s/ip host $host//;
        }
    }
    
    # Bug 11227
    $data        =~ s/ntp authentication-key \d+ md5 \S+//g;
    $compareData =~ s/ntp authentication-key \d+ md5 \S+//g;

    # Bug 146406
    $data        =~ s/\n\n//g;
    $compareData =~ s/\n\n//g;

	if ($data eq $compareData)
	{
		return "true";
	}

	# short-circuit expensive line-by-line comparison if not needed
	# second way is faster by factor of 2 on large configs
	#if( not $data =~ /modem +autoconfigure|dlsw remote-peer/)
	if( not ($data =~ /modem +autoconfigure/ || $data =~/dlsw remote-peer/) )
	{
		if( $logLevel eq "0" )
        {
			$data =~ s/([^\x20-\x7F])/"[" . ord($1) . "]"/eg;
			$compareData =~ s/([^\x20-\x7F])/"[" . ord($1) . "]"/eg;
			return "false comparison:\n       data '$data'\ncompared to '$compareData'";
		}
		else
        {
			return "false";
		}
	}
	
	# Handle the odd cases; AUX port speed changes on Cisco devices with autoconfigure enable
	@data = split(/\n/, $data);
	@compareData = split(/\n/, $compareData);
	$data = $compareData = "";

	# The theory behind the following is that a section can be represented 
	# by a number (in this case, 1 == (line aux X); 2 could enumerate
	# (line vty \d+) or something entirely different. While within a section,
	# if a match is found in part B and we're parsing the enumerated section,
	# modify the command to mask it. This allows for comparsisons of similar 
	# commands while in different sections -- the obvious output is to not mask
	# the command at that point. See the example for future modifications.
	#
	# The script can never be in two sections at once.
	$match = 0;
	foreach $line (@data)
	{
		if($line =~ /modem +autoconfigure/)
		{
			$match = 1;
		}
		## Example: 
		#elsif ($line =~ /line vty \d+/)
		#{
		#	$match = 2;
		#}
		elsif ($line =~ /\!/)
		{
			$match = 0;
		}
		# Part B
		if($match == 1 && $line =~ /speed \d+/)
		{
			$line =~ s/ *\S*speed \d+\s*//;
			if($line =~ /\s*/)
			{
				$line = "";
			}
		}
		## Example:
		#elsif ($match == 2 && $line =~ /exec-timeout +\d+ +\d+/)
		#{
		#	$line =~ s/\s+exec-timeout +\d+ +\d+//;
		#}
		$data = $data . $line . "\n" if $line;
	}

	$match = 0;
	foreach $line (@compareData)
	{
		if($line =~ /modem +autoconfigure/)
		{
			$match = 1;
		}
		#elsif ($line =~ /line vty \d+/)
		#{
		#	$match = 2;
		#}
		elsif ($line =~ /\!/)
		{
			$match = 0;
		}

		if($match == 1 && $line =~ /speed \d+/)
		{
			$line =~ s/ *\S*speed \d+\s*//;
			if($line =~ /\s*/)
			{
				$line = "";
			}
		}
		#elsif ($match == 2 && $line =~ /exec-timeout +\d+ +\d+/)
		#{
		#	$line =~ s/\s+exec-timeout +\d+ +\d+//;
		#}
		$compareData = $compareData . $line . "\n" if $line;
	}

	# Bug 6435 -- Pull out DLSW peers and perform masking seperately
	# Only process if both configs have remote-peers identified
	if($data =~ /dlsw remote-peer/ && $compareData =~ /dlsw remote-peer/){
		while($data =~ /dlsw remote-peer (\d+) ([\S ]+)/gc)
		{
			# Store the ring group id in the hash; it won't be used as part of the masking query
			$data_dlsw{$2} = $1;
		}
		while($compareData =~ /dlsw remote-peer (\d+) ([\S ]+)/gc)
		{
			$compareData_dlsw{$2} = $1;
		}
		@similarity = ();
		foreach ( keys %data_dlsw ) 
		{
			push(@similarity, $_) if exists $compareData_dlsw{$_};
		}

		# Mask all similar items from the configuration but leave the ring group id in tact
		foreach $peer (@similarity)
		{
			$data        =~ s/(dlsw remote-peer \d+) $peer/$1 xxx/g;
			$compareData =~ s/(dlsw remote-peer \d+) $peer/$1 xxx/g;
		}
	}

	if ($data eq $compareData)
	{
		return "true";
	}
	elsif ( $logLevel eq "0" )
    {
		$data =~ s/([^\x20-\x7F])/"[" . ord($1) . "]"/eg;
		$compareData =~ s/([^\x20-\x7F])/"[" . ord($1) . "]"/eg;
		return "false comparison:\n       data '$data'\ncompared to '$compareData'";
	}
	else
	{
		return "false";
	}
}

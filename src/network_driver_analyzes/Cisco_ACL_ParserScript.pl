#! /usr/local/bin/perl

sub getACLtype
{
	my ($aclid) = @_;
	
	my $type = "";

    if ($aclid =~ /(\d+)/)
    {
    	my $intid = $1;
    	if ($intid >= 1 && $intid <= 99)
    	{
    		$type = "IP standard";
    	}
    	elsif ($intid >= 100 && $intid <= 199)
    	{
    		$type = "IP extended";
    	}
    	elsif ($intid >= 200 && $intid <= 299)
    	{
    		$type = "protocol type-code";
    	}
    	elsif ($intid >= 300 && $intid <= 399)
    	{
    		$type = "DECnet";
    	}
    	elsif ($intid >= 400 && $intid <= 499)
    	{
    		$type = "XNS standard";
    	}
    	elsif ($intid >= 500 && $intid <= 599)
    	{
    		$type = "XNS extended";
    	}
    	elsif ($intid >= 600 && $intid <= 699)
    	{
    		$type = "Appletalk";
    	}
    	elsif ($intid >= 700 && $intid <= 799)
    	{
    		$type = "48-bit MAC address";
    	}
    	elsif ($intid >= 800 && $intid <= 899)
    	{
    		$type = "IPX standard";
    	}
    	elsif ($intid >= 900 && $intid <= 999)
    	{
    		$type = "IPX extended";
    	}
    	elsif ($intid >= 1000 && $intid <= 1099)
    	{
    		$type = "IPX SAP";
    	}
    	elsif ($intid >= 1100 && $intid <= 1199)
    	{
    		$type = "extended 48-bit MAC address";
    	}
    	elsif ($intid >= 1200 && $intid <= 1299)
    	{
    		$type = "IPX summary address";
    	}
    	elsif ($intid >= 1300 && $intid <= 1999)
    	{
    		$type = "IP standard";
    	}
    	elsif ($intid >= 2000 && $intid <= 2699)
    	{
    		$type = "IP extended";
    	}
    	else
    	{
    		$type = "UNKNOWN";
    	}
    }
    else
    {
    	#DOC $type = "<i>named</i>";
    	$type = $aclid;
    }
    
	return $type;
}

sub getData
{
	my ($aclid, $comment) = @_;

	my $handle = $aclid;
	if($handle < 1000 && $handle =~ /^\d+$/)
	{
		$handle = sprintf("% 4d", $handle);
	}
	
	if ($comment =~ /(^|\n)!!ACLNAME: (.*)/)
	{
		$handle = $2;
	}

	# strip out any !!ACL* comments
	$comment =~ s/(^|\n)!!ACL.*//g;
	
	# now make this nice and clean	
	$comment =~ s/(^|\n)!![ \t]*(.*)/$1$2/g;
	$comment =~ s/^\n+//;
	$comment =~ s/\n+$//;
	
	$type = getACLtype($aclid);
				
	return ($aclid, $handle, $type, $comment);
}

sub GetACLs
{
	my($config) = @_;

	$config =~ s/\r//g; # get rid of carriage returns in TC added comments

	my(@ids) = ( "startids" );
	my(@types) = ( "starttypes" );
	my(@handles) = ( "starthandles" );
	my(@comments) = ( "startcomments" );
	my(@scripts) = ( "startscripts" );
	my(@applications) = ( "startapplications" );

	my($count) = 1;

	# parse scripts
	my $lastaclid = "**first**";
	my $aclconfig = "";

	my $aclid = "";
	my $lastcomment = "";
	
	# Pull out access-lists
	while ($config =~ /\n((!!.*\n)*|\n)( *access-list (\S+).*)/gc)
	{
		$aclid = $4;
		my $cmdline = $3;
		my $comment = $1;

		next if $aclid == 0;

		if ($aclid ne $lastaclid)
		{
			if ($lastaclid ne "**first**")
			{
				($ids[$count], $handles[$count], $types[$count], $comments[$count]) = getData($lastaclid, $lastcomment);

				$count++;
				$lastcomment = "";
			}
			
			$lastaclid = $aclid;
		}
		
		if ($comment ne "" && $lastcomment eq "")
		{
			$lastcomment = $comment;
		}

		$scripts[$count] .= "$cmdline\n";
	}

	if ($aclid ne "")
	{
		($ids[$count], $handles[$count], $types[$count], $comments[$count]) = getData($lastaclid, $lastcomment);
		$count++;
	}

	# Pull out as-path access-lists
	pos($config) = 0;
	my $lastaclid = "**first**";
	my $aclconfig = "";

	my $aclid = "";
	my $lastcomment = "";
	
	while ($config =~ /\n((!!.*\n)*|\n)( *ip as-path access-list (\S+) .*)/gc)
	{
		$aclid = $4;
		my $cmdline = $3;
		my $comment = $1;

		next if $aclid == 0;

		if ($aclid ne $lastaclid)
		{
			if ($lastaclid ne "**first**")
			{
				($ids[$count], $handles[$count], $types[$count], $comments[$count]) = getData($lastaclid, $lastcomment);
				# Modify for  "ip as-path access-list" 
				$types[$count] = "IP as-path access-list";
				$count++;
				$lastcomment = "";
			}
			
			$lastaclid = $aclid;
		}
		
		if ($comment ne "" && $lastcomment eq "")
		{
			$lastcomment = $comment;
		}

		$scripts[$count] .= "$cmdline\n";
	}

	if ($aclid ne "")
	{
		($ids[$count], $handles[$count], $types[$count], $comments[$count]) = getData($lastaclid, $lastcomment);
		# Modify for  "ip as-path access-list" 
		$types[$count] = "IP as-path access-list";

		$count++;
	}

	# Pull out prefix-lists
	pos($config) = 0;
	my $lastaclid = "**first**";
	my $aclconfig = "";

	my $aclid = "";
	my $lastcomment = "";
	
	while ($config =~ /\n((!!.*\n)*|\n)( *ip prefix-list (\S+) .*)/gc)
	{
		$aclid = $4;
		my $cmdline = $3;
		my $comment = $1;

		if ($aclid ne $lastaclid)
		{
			if ($lastaclid ne "**first**")
			{
				($ids[$count], $handles[$count], $types[$count], $comments[$count]) = getData($lastaclid, $lastcomment);
				# Modify for  "ip prefix-list" 
				$types[$count] = "IP prefix-list";
				$count++;
				$lastcomment = "";
			}
			
			$lastaclid = $aclid;
		}
		
		if ($comment ne "" && $lastcomment eq "")
		{
			$lastcomment = $comment;
		}

		$scripts[$count] .= "$cmdline\n";
	}

	if ($aclid ne "")
	{
		($ids[$count], $handles[$count], $types[$count], $comments[$count]) = getData($lastaclid, $lastcomment);
		# Modify for  "ip prefix-list" 
		$types[$count] = "IP prefix-list";

		$count++;
	}
	
	# Look for named access lists
	pos($config) = 0;
	my $lastaclid = "**first**";
	my $aclconfig = "";

	my $aclid = "";
	my $lastcomment = "";
	while($config =~ /\n((!!.*\n)*|\n)( *ip access-list \S+ (\S+).*)/gc)
	{
		$aclid = $4;
		$start = pos($config);
		my $cmdline = $3;
		my $comment = $1;

		($ids[$count], $handles[$count], $types[$count], $comments[$count]) = getData($aclid, $comment);

		# Build cmdline
		if($config =~ /(\n!|\n\S+)/gc)
		{
			$end = pos($config) - length($1);
			pos($config) = $end - length($1);
			$cmdline .= substr($config, $start, $end - $start);
		}

		# Set type appropriately
		if($cmdline =~ /(ip access-list \S+) +/)
		{
			$types[$count] = $1;
            $types[$count] =~ s/^ip /IP /;
		}

		$scripts[$count] .= "$cmdline\n";
		$count++;
	}

	# Determine which redundant sections may be in the configuaration
	foreach $section (qw(bgp egp eigrp igrp isis iso-igrp mobile odr ospf rip))
	{
		if($config =~ /router $section/)
		{
			push(@sections, $section);
		}
	}

	# applications
	my $index = 1;
	while ($index < $count)
	{
		my $aclid = $ids[$index];
		my $type  = $types[$index];

		my $regex_aclid = $aclid;
		$regex_aclid =~ s/([\.\*\+\?\^\$\{\}\(\)\|\[\]\\\/])/\$1/g;

		my $apply = "";
		pos($config) = 0;

		# Process access-lists as originally designed. Process prefix-lists and as-path lists seperately
		if($type !~ /(prefix-list|as-path)/){
			# Check all interfaces -- look for multiple uses of single ACL
			while ($config =~ /\n(( *interface.*)[\s\S]*?(\n!))/gc)
			{
				$define = $2;
				$int_count = 0;
				$subConfig = $1;

				#DOC application: interface ip access-group
				while($subConfig =~ /( +ip access-group $regex_aclid .*)/gc)
				{
					if($int_count == 0)
					{
						$apply .= "$define\n";
					}
					$apply .= "$1\n";
					$int_count++;
				}
                pos($subConfig) = 0;
                while($subConfig =~ /( +bridge-group \S+ (\S+-address-list|input-type-list) $regex_aclid)\n/gc)
                {
                    if($int_count == 0)
                    {
                        $apply .= "$define\n";
                    }
                    $apply .= "$1\n";
                    $int_count++;
                }
			}
			pos($config) = 0;
			while ($config =~ /\n(( *line vty.*)[\S\s]+?)(?=(\n!|\nline))/gc) 
			{
				my $vtyline = $2;
				#DOC application: line vty access-class
				if ($1 =~ /\n( +access-class $regex_aclid .*)/)
				{
					$apply .= "$vtyline\n$1\n!\n";
				}
			}
			pos($config) = 0;
			while($config =~ /\n(ntp access-group (peer|serve-only) $regex_aclid)\s*\n/gc)
			{
				$apply .= "$1\n";
			}
			pos($config) = 0;
			while($config =~ /\n(ip nat [\S ]+ list $regex_aclid pool.*)\s/gc)
			{
				$apply .= "$1\n";
			}
			# Note: route-maps can have several match statements, so this section must be
			# grouped into a block and checked one block at a time
			#
			#DOC application: route-map match ip address 
			pos($config) = 0;
			if($config =~ /route-map/){ # Otherwise, skip this section
				while($config =~ /(route-map [\S ]+)/gc){
					$mapName = $1;

					$start = pos($config);
					$end = pos($config) if($config =~ /\n!/gc);
					$subConfig = substr($config, $start, $end - $start);


					while ($subConfig =~ /\n( *match ip address[\S ]*? $regex_aclid *.*\s+)/gc) 
					{
						# Ensure that we have a full match
						$tmp = "$mapName" . "$subConfig\n";
						$apply .= "$tmp" if($tmp =~ /match ip address.*\s+$regex_aclid\s+/);
					}
				}
			}

			pos($config) = 0;
			#DOC application: class-map match access-group
			#while ($config =~ /\n(class-map \S+.*)(\n *description.*)?\n( *match access-group (name )?$aclid\s+)/gc) 
			#{
			#	$apply .= "$1\n$3\n!\n";
			#}
			while ($config =~ /\n(class-map \S+.*)/gc) {
				$classmap = $1;
				chomp $classmap;
				$start = pos($config);
				$end = (pos($config) - 2) if($config =~ /\n\S/gc);
				pos($config) = pos($config) -2;
				$subConfig = substr($config, $start, $end - $start);

				$found = 0;
				while ($subConfig =~ /( *match access-group (name )?$regex_aclid)(\s|\n|$)/gc)
				{
					$matchline = $1;
					$found = 1;
					$classmap .= "\n$matchline";
				}

				$apply .= "$classmap\n!\n" if ($found == 1);
			}

			pos($config) = 0;
			#DOC application: snmp-server
			# snmp-server community mystring RO 98
			while ($config =~ /\n(snmp-server community .* $regex_aclid *)\n/gc) 
			{
				$apply .= "$1\n";
			}
	
			pos($config) = 0;
			#DOC application: list protocol list
			while ($config =~ /(\S+-list \d+ protocol [\S ]+ list $regex_aclid *)\n/gc)
			{
				$apply .= "$1\n";
			}
			
		} # endif $type !~ (prefix|as-path)
		else
		{

			if($config =~ /route-map/){ # Otherwise, ignore this section

				while($config =~ /(route-map [\S ]+)/gc){
					$mapName = $1;

					$start = pos($config);
					$end = pos($config) if($config =~ /\n!/gc);
					$subConfig = substr($config, $start, $end - $start);

					if($type =~ /as-path/){
						pos($subConfig) = 0;
						while ($subConfig =~ /\n( *match as-path $regex_aclid *.*\s+)/gc)
						{
							$tmp = "$mapName". "$subConfig\n!\n";
							$apply .= "$tmp" if($tmp =~ /match as-path.*\s+$regex_aclid\s+/);
						}
					}
					if($type =~ /prefix-list/){
						pos($subConfig) = 0;
						while ($subConfig =~ /\n( *match ip address prefix-list $regex_aclid *.*\s+)/gc)
						{
							$tmp = "$mapName" . "$subConfig\n!\n";
							$apply .= "$tmp" if($tmp =~ /match ip address prefix-list.*\s+$regex_aclid\s+/);
						}
					}
				} # end while

			}
			
		}
		# For "router" sections defined in the configuration (see above), check for 
		# bgp egp eigrp igrp isis iso-igrp mobile odr ospf rip
		#DOC application: router <i>protocol</i> neighbor filter-list
		#DOC application: router <i>protocol</i> neighbor distribute-list
		foreach $section (@sections)
		{
			pos($config) = 0;
			if($config =~ /(router $section[ ]*.*)/gc)
			{
				$start = pos($config);
				$Cmd = $1;
				if($config =~ /\n!/gc)
				{
					$end = pos($config);
					$SubConfig = substr($config, $start, $end - $start);
				}
				else
				{
					$SubConfig = substr($config, $start);
				}
					
				$ACLs = 0;
				while ($SubConfig =~ /\n( +neighbor \S+ (filter-list|distribute-list|prefix-list) $regex_aclid .*)/gc)
				{
					$matchType = $2;
					$match = $1;

					if( ($matchType eq "filter-list" && $type eq "ip as-path access-list") ||
					    ($matchType eq "prefix-list" && $type eq "ip prefix-list") ||
						($matchType =~ /distribute/ && $type !~ /(filter|prefix)/) )
					{
						$apply .= "$Cmd\n" if $ACLs == 0;
						$ACLs++;
						$apply .= "$match\n";
					}
				}
		
				pos($SubConfig) = 0;
				while ($SubConfig =~ /\n( +distribute-list( prefix)? $regex_aclid .*)/gc)
				{
					$apply .= "$Cmd\n" if $ACLs == 0;
					$ACLs++;
					$apply .= "$1\n";
				}
	
				pos($SubConfig) = 0;
				while ($SubConfig =~ /\n( +offset-list $regex_aclid .*)/gc)
				{
					$apply .= "$Cmd\n" if $ACLs == 0;
					$ACLs++;
					$apply .= "$1\n";
				}

			}
		}
		
		$applications[$index] = $apply;
		$index++;
	}


	# close arrays
	$ids[$count] = "endids";
	$types[$count] = "endtypes";
	$handles[$count] = "endhandles";
	$comments[$count] = ( "endcomments" );
	$scripts[$count] = "endscripts";
	$applications[$count] = "endapplications";

	return (@ids, @types, @handles, @comments, @scripts, @applications);
}

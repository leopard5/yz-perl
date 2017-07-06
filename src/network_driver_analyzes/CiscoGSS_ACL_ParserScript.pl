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
    		$type = "protocal type-code";
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
    	$type = $aclid;
    }
    
	return $type;
}

sub getData
{
	my ($aclid, $comment) = @_;
	my $handle = $aclid;

	# NOTE: if comment char is '!' use following code, 
	# NOTE: otherwise you MUST change the comment char to match the driver's
	# NOTE: if comment char is not supported, comment out from here to "NOTE: EndComment" below
	if ($comment =~ /(^|\n)!!ACLNAME: (.*)/)
	{
		$handle = $2;
		# NOTE: change comment char if necessary
		$comment =~ s/(^|\n)!!ACLNAME: .*//;
	}

	# strip out any !!ACL* comments
	# NOTE: change comment char if necessary
	$comment =~ s/(^|\n)!!ACL.*//g;
	
	# NOTE: change comment char if necessary
	$comment =~ s/(^|\n)!!(.*)/$1$2/g;
	$comment =~ s/^\n+//;
	$comment =~ s/\n+$//;
	# NOTE: EndComment

	$type = getACLtype($aclid);

	return ($aclid, $handle, $type, $comment);
}

sub GetACLs
{
	my($config) = @_;

	$config =~ s/\r//g;

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

	# NOTE: if device does not support comment char, use line below	
	#while ($config =~ /\n( *access-list (\S+).*)/gc)
	# NOTE: if device supports comment char, use line below
	# NOTE: if device comment char is not '!', change comment char
	while ($config =~ /\n((!!.*\n)*|\n)( *(access-list|access group) (\S+).*)/gc)
	{
		# NOTE: if device does not support comment char, use following three lines
		#$aclid = $2;
		#my $cmdline = $1;
		#my $comment = "";
		# NOTE: if device does support comment char, use following three lines
		$aclid = $5;
		my $cmdline = $3;
		my $comment = $1;

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

		# "access-list" are ACL scripts,... "access group" are ACL application statements
		if ($cmdline =~ /access-list/) {
			$scripts[$count] .= "$cmdline\n";
		} elsif ($cmdline =~ /access group/) {
			$applications[$count] .= "$cmdline\n";
		}
	}

	# add in last acl, if any
	if ($aclid ne "")
	{
		($ids[$count], $handles[$count], $types[$count], $comments[$count]) = getData($lastaclid, $lastcomment);
		
		$count++;
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

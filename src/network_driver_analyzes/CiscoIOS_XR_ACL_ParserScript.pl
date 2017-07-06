#! /usr/local/bin/perl

sub getData
{
	my ($aclid, $type) = @_;

	my $handle = $aclid;
	my $comment = "";

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

	while ($config =~ /\n( *(\S+) access-list (\S+)\n[\n\S\s ]+?\n\!)/gc)
	{
		my $cmdline = $1;
		$aclid = $3;
		$type = $2;
		my $comment = "";

		($ids[$count], $handles[$count], $types[$count], $comments[$count]) = getData($aclid, $type);

		$scripts[$count] .= "$cmdline\n";
		$count++;
	}

	# applications
	my $index = 1;
	while ($index < $count)
	{
		my $aclid = $ids[$index];
		my $type = $types[$index];

		my $apply = "";
		pos($config) = 0;
		# Check all interfaces -- look for multiple uses of single ACL
		while ($config =~ /\n((interface \S+)\n[\n\S\s ]+?\n!)/gc)
		{
			$int = $1;
			$define = $2;

			if($int =~ /\n( *$type access-group $aclid .*)/)
			{
				$apply .= "$define\n$1\n!\n";
			}
		}
		pos($config) = 0;
		# Check SNMP applications
		while ($config =~ / *(snmp-server community \S+ \S+ $aclid)\n/gc)
		{
			$apply .= "$1\n";
		}
		pos($config) = 0;
		while ($config =~ / *(snmp-server community \S+ \S+ (SDROwner|SystemOwner) $aclid)\n/gc)
		{
			$apply .= "$1\n";
		}
		pos($config) = 0;
		while ($config =~ / *(snmp-server user \S+ \S+ .*$aclid)\n/gc)
		{
			$apply .= "$1\n";
		}
		pos($config) = 0;
		while ($config =~ / *(snmp-server group \S+ \S+ .*$aclid)\n/gc)
		{
			$apply .= "$1\n";
		}
		pos($config) = 0;
		# Check lines
		while ($config =~ /\n( *(line [\S ]+)\n[\n\S\s ]+?\n\!\n)/gc)
		{
			$define = $2;

			while($1 =~ /\n( *access-class.*$aclid.*)/)
			{
				$apply .= "$define\n$1\nexit\n";
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

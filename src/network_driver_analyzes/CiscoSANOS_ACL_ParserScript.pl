#! /usr/local/bin/perl

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

	my $aclid = "";
	my %ACL_HASH=();
	
	#Pull out IPv4 access-lists
	#ip access-list hpacl permit ip any any
	#ip access-list hpacl permit tcp any any
	while ($config =~ /\n\s*(ip +access-list +(\S+).*)/gc)
	{
		$aclid = $2;
		my $cmdline = $1;
		
		$ACL_HASH{$aclid}.=$cmdline."\n";
	}
	
	pos($config) = 0;
	#Pull out IPv6 access-lists
	#ipv6 access-list hpaclv6
	# permit 58 any any
	while ($config =~ /(pv6 access-list (\S+)[\S\s]*?\n)\S/gc)
	{
		$aclid = $2;
		my $cmdline = "i".$1;
		
		$ACL_HASH{$aclid}.=$cmdline."\n";
	}

	my %ACL_APP_HASH=();
	my $define = "";
	my $subConfig = "";
	pos($config) = 0;
	# Check all interfaces -- look for multiple uses of single ACL
	while ($config =~ /((nterface [\S ]+)[\S\s]*?)(\n\n|\ni|\n\s*$)/gc)
	{
		$define = "i".$2;
		$int_count = 0;
		$subConfig = $1;

		#DOC application: interface ip access-group
		while($subConfig =~ /( +(ip access-group|ipv6 traffic-filter) (\S+) .*)/gc)
		{
			my $apply = "";
			if($int_count == 0)
			{
				$apply .= "$define\n";
			}
			$apply .= "$1\n";
			$ACL_APP_HASH{$3} .= $apply;
			$int_count++;
		}
	}
	
	my @acl_names = keys %ACL_HASH;
	foreach $acl_name (@acl_names)
	{
		$ids[$count]=$acl_name;
		$handles[$count]=$acl_name;
		$comments[$count]="";
		$scripts[$count] = $ACL_HASH{$acl_name};
		$types[$count]="IP extended";
		$types[$count]="IPv6 extended" if ($scripts[$count] =~ /^\s*ipv6/g);
		$applications[$count]="";
		if ($ACL_APP_HASH{$acl_name})
		{
			$applications[$count] = $ACL_APP_HASH{$acl_name};
		}
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

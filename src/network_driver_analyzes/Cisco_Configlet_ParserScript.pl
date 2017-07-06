#! /usr/local/bin/perl

sub findBlock
{
	my($config, $startBlock, $endBlock, $helper) = @_;

	# endBlock may be identical to startBlock == find all lines with this information
	if($startBlock eq $endBlock){
		@config = split(/\n/, $config);
		@lines = grep (/$startBlock/, @config);
		$config = "";
		foreach $line (@lines){
			$config .= "$line\n";
		}
	}
	else
	{
		# This value must be set by every parser
		# endBlock may be set to *UNSPECIFIED*
		$endBlock = "!" if($endBlock eq "*UNSPECIFIED*");

        if($helper eq "C_INTERFACE")
        {
            $startBlock = "\ninterface $startBlock";
        }
                if($config =~ /([\S ]*$startBlock)/gc){
                        $start = pos($config) - length($1);

                        if($config =~ /$endBlock/gc){
                                $end = pos($config);
                                $config = substr($config, $start, $end - $start);
                        }
                        else
                        {
                                $config = substr($config, $start);
                        }

                }
                else
                {
                        $config = "";
                }
        }

	return $config;
	
}

# Find QoS tags in a configuration block. Limited regexp values may be returned
# such as "^string" where the '^' represents the regexp character for start of line.
# This is necessary for bypass parser compatibility where no regexeps are used. 
# The bypass parser will convert a '^' at index 0 to '\n'
#
# Return startBlock and endBlock for configLet parser to use
sub findQoS
{
	my($config, $fullConfig, $startBlock, $endBlock, $helper) = @_;

    my $block = "";
    if($helper eq "C_QOS")
    {
        my %ids = ();
        # Parse ACL IDs from block (usually a configlet interface block)
#        while($config =~ /access-group (\d+) /gc)
#        {
#                    push(@ids, "access-list $1");
#        }
        pos($config) = 0;
        while($config =~ /custom-queue-list (\d+)/gc)
        {
                    # Regexp included for finding command in config
                         # startBlock          # endBlock
                    $ids{"^queue-list $1 "} = "^queue-list $1 ";
        }
        pos($config) = 0;
        while($config =~ /priority-group (\d+)/gc)
        {
                    # Regexp included for finding command in config
                    $ids{"^priority-list $1 "} = "^priority-list $1 ";
        }
        pos($config) = 0;
        while($config =~ /traffic-shape group (\d+)/gc)
        {
                    # Regexp included for finding command in config
                    $ids{"^access-list $1 "} = "^access-list $1 ";
        }
        pos($config) = 0;
        while($config =~ /rate-limit \S+ access-group (\S+)/gc)
        {
                    # Regexp included for finding command in config
                    $ids{"^access-list $1 "} = "^access-list $1 ";
        }
        pos($config) = 0;
        while($config =~ /rate-limit \S+ qos-group (\S+)/gc)
        {
                    # Regexp included for finding command in config
                    $ids{"^access-list $1 "} = "^access-list $1 ";
        }
        pos($config) = 0;
        while($config =~ /ip policy (route-map (\S+))/gc)
        {
                    $ids{"\n$1"} = "!";

                    # Find access-lists inside of route-map 
                    my $routeMap = "";
                    pos($fullConfig) = 0;
                    my $routeMapPattern = $1;
                    while($fullConfig =~ /\n*($routeMapPattern [\S\n ]*?!)/gc)
                    {
                        $routeMap .= $1 . "\n";
                    }
                    while($routeMap =~ /match ip (address|next-hop) ([\S ]+)/gc)
                    {
                            my @acls = split(/\s/, $2);
                            foreach $aclId (@acls)
                            {
                                    $ids{"^access-list $aclId "} = "^access-list $aclId ";
                            }
                    }
        }
        pos($config) = 0;
        while($config =~ /service-policy \S+ (\S+)/gc)
        {
                    # Regexp included for finding command in config
                    $ids{"\npolicy-map $1"} = "!";

                    # Find classes if used by policy-map
                    my $routeMap = "";
                    pos($fullConfig) = 0;
                    my $routeMapPattern = "policy-map $1";
                    while($fullConfig =~ /\n*($routeMapPattern[\S\n ]*?!)/gc)
                    {
                        $routeMap .= $1 . "\n";
                    }
                    # policy-maps may have classes
                    while($routeMap =~ /class (\S+)/gc)
                    {
                            my @classes = split(/\s/, $1);
                            foreach $class (@classes)
                            {
                                    pos($fullConfig) = 0;
                                    # classes may have access-groups
                                    if($fullConfig =~ /\n*(class-map $class[\S\n ]*?)(class-map|!)/)
                                    {
                                        my $classMap = $1;
                                        $ids{ "\nclass-map $class"} = "\n$2";
                                        if($classMap =~ /match access-group (\S+)/)
                                        {
                                                $ids{"^access-list $1 "} = "^access-list $1 ";
                                        }
                                    }
                            }
                    }
        }

        # Sort the list by the keys for a reasonably alphabetical list
        my @sortedKeys = sort (keys %ids);
        for($i = 0; $i <= $#sortedKeys; $i++) {
                my $key = $sortedKeys[$i];
                if($i > 0) { $block .= ","; }
                $block .= "$key,$ids{$key}";
        }
    }

	return $block;
	
}

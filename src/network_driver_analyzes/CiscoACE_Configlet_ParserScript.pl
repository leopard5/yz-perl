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
		$endBlock = "\n\n" if($endBlock eq "*UNSPECIFIED*");

        if($helper eq "C_INTERFACE")
        {
            $startBlock = "interface $startBlock";
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

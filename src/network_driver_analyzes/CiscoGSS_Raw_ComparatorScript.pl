#! /usr/local/bin/perl

sub compare
{
	my($data, $compareData, $maskWLCCPPwd,$logLevel) = @_;

	# Extract the running configuration from the multiconfig block structure... since  
	# that's the only piece worth doing comparison on [startup doesn't contain anything else]
	if ($data =~ /running configuration\s+\#\=+\s+([\S\s]+)(\s+\#\=+)/) {
		$data = $1;

		# We've trimmed the header, but there are trailing multiconfig blocks
		# that are picked up by the greedy operator above... trim them.
		$len  = index( $data, "#======" );
		$data = substr( $data, 0, $len );
		$data =~ s/\s+$/\n/;
	}
	if ($compareData =~ /running configuration\s+\#\=+\s+([\S\s]+)(?=\s+\#\=+)/) {
		$compareData = $1;

		# We've trimmed the header, but there are trailing multiconfig blocks
		# that are picked up by the greedy operator above... trim them.
		$len = index( $compareData, "#======" );
		$compareData = substr( $compareData, 0, $len );
		$compareData =~ s/\s+$/\n/;
	}

	# There is a date string at the start of the "show tech-support config" data... remove it
	$data        =~ s/(Sun|Mon|Tue|Wed|Thu|Fri|Sat) (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) .*//;
	$compareData =~ s/(Sun|Mon|Tue|Wed|Thu|Fri|Sat) (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) .*//;

	# Version string contains an uptime counter
	$data        =~ s/Uptime: .*//;
	$compareData =~ s/Uptime: .*//;

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

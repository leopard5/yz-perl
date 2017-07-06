#! /usr/local/bin/perl

sub compare
{
	my($data,$compareData,$logLevel) = @_;

	$data =~ s/\n\s+reliability \S+, txload.*//g;
	$data =~ s/\n\s+Last input \S+, output \S+,.*//g;
	$data =~ s/\n\s+Last clearing of \"show .*//g;
	$data =~ s/\n\s+Input queue:.*//g;
	$data =~ s/\n\s+Output queue \S+, .*//g;
	$data =~ s/\n\s+(Reserved )?Conversations.*//g;
	$data =~ s/\n\s+\d+ minute (in|out)put rate .*//g;
	$data =~ s/\n\s+\d+ packets input, .*//g;
	$data =~ s/\n\s+Received \d+ broadcasts.*//g;
	$data =~ s/\n\s+\d+ watchdog.*//g;
	$data =~ s/\n\s+\d+ input packets with dribble.*//g;
	$data =~ s/\n\s+\d+ packets output,.*//g;
	$data =~ s/\n\s+\d+ babbles,.*//g;
	$data =~ s/\d+ output errors, \d+ collisions,//g;
	$data =~ s/Bytes Received.*//g;
	$data =~ s/\d+ unicast packets//g;
	$data =~ s/\d+ bytes//g;
	$data =~ s/\d+ (input|output) errors.*//g;
	$data =~ s/\d+ multicast//g;
	$data =~ s/\d+ broadcast//g;

	$compareData =~ s/\n\s+reliability \S+, txload.*//g;
	$compareData =~ s/\n\s+Last input \S+, output \S+,.*//g;
	$compareData =~ s/\n\s+Last clearing of \"show .*//g;
	$compareData =~ s/\n\s+Input queue:.*//g;
	$compareData =~ s/\n\s+Output queue \S+, .*//g;
	$compareData =~ s/\n\s+(Reserved )?Conversations.*//g;
	$compareData =~ s/\n\s+\d+ minute (in|out)put rate .*//g;
	$compareData =~ s/\n\s+\d+ packets input, .*//g;
	$compareData =~ s/\n\s+Received \d+ broadcasts.*//g;
	$compareData =~ s/\n\s+\d+ watchdog.*//g;
	$compareData =~ s/\n\s+\d+ input packets with dribble.*//g;
	$compareData =~ s/\n\s+\d+ packets output,.*//g;
	$compareData =~ s/\n\s+\d+ babbles,.*//g;
	$compareData =~ s/\d+ output errors, \d+ collisions,//g;
	$compareData =~ s/Bytes Received.*//g;
	$compareData =~ s/\d+ unicast packets//g;
	$compareData =~ s/\d+ bytes//g;
	$compareData =~ s/\d+ (input|output) errors.*//g;
	$compareData =~ s/\d+ multicast//g;
	$compareData =~ s/\d+ broadcast//g;

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

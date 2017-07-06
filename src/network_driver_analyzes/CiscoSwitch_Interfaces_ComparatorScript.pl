#! /usr/local/bin/perl

sub compare
{
	my($data,$compareData,$logLevel) = @_;

	$data =~ s/Total good frames +\d+ +Total frames +\d+//g;
	$data =~ s/Total octets +\d+ +Total octets +\d+//g;
	$data =~ s/Broadcast\/multicast frames +\d+ +Broadcast\/multicast frames +\d+//g;
	$data =~ s/Broadcast\/multicast octets +\d+ +Broadcast\/multicast octets +\d+//g;
	$data =~ s/Good frames forwarded +\d+ +Deferrals +\d+//g;
	$data =~ s/Frames filtered +\d+ +Single collisions +\d+//g;
	
	$compareData =~ s/Total good frames +\d+ +Total frames +\d+//g;
	$compareData =~ s/Total octets +\d+ +Total octets +\d+//g;
	$compareData =~ s/Broadcast\/multicast frames +\d+ +Broadcast\/multicast frames +\d+//g;
	$compareData =~ s/Broadcast\/multicast octets +\d+ +Broadcast\/multicast octets +\d+//g;
	$compareData =~ s/Good frames forwarded +\d+ +Deferrals +\d+//g;
	$compareData =~ s/Frames filtered +\d+ +Single collisions +\d+//g;


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

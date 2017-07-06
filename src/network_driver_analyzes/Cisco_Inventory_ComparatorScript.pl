#! /usr/local/bin/perl

sub compare
{
	my($data,$compareData,$logLevel) = @_;

	$data        =~ s/insertion time:? .*\(?.+ ago\)?/insertion time XX:XX:XX ago/gi;
	$compareData =~ s/insertion time:? .*\(?.+ ago\)?/insertion time XX:XX:XX ago/gi;

	$data        =~ s/uptime is [\S ]+/uptime is xxx/g;
	$compareData =~ s/uptime is [\S ]+/uptime is xxx/g;

	$data        =~ s/System restarted.*//g;
	$compareData =~ s/System restarted.*//g;

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

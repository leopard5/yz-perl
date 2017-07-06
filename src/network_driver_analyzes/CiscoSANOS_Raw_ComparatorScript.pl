#! /usr/local/bin/perl

# If there is nothiing to mask during comparison, do not include this component
sub compare
{
	my($data,$compareData,$logLevel) = @_;

	$data =~ s/^![\S ]*[\r\n]//g;
	$compareData =~ s/^![\S ]*[\r\n]//g;

	$data =~ s/ +$//mg;
	$compareData =~ s/ +$//mg;
	
	$data =~ s/^ +//mg;
	$compareData =~ s/^ +//mg;

	$data =~ s/uptime is .*//;
	$compareData =~ s/uptime is .*//;

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

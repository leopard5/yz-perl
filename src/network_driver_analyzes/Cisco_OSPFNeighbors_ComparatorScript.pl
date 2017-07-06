#! /usr/local/bin/perl

sub compare
{
	my($data,$compareData,$logLevel) = @_;

	$data =~ s/(\n\S+ +\d+ +[\s\S]+?) +\d+\S+ +(\S+ +\S+)/$1 xxx $2/g;
	$compareData =~ s/(\n\S+ +\d+ +[\S\s]+?) +\d+\S+ +(\S+ +\S+)/$1 xxx $2/g;

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

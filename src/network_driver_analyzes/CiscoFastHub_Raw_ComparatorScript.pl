#! /usr/local/bin/perl

# If there is nothing to mask during comparison, do not include this component
sub compare
{
	my($data,$compareData,$logLevel) = @_;

	$data        =~ s/Bytes Received.*//g;
	$compareData =~ s/Bytes Received.*//g;
	
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

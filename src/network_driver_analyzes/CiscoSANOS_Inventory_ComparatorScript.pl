#! /usr/local/bin/perl

sub compare
{
    my($data,$compareData,$logLevel) = @_;

    $data        =~ s/kernel uptime.*/masked/g;
    $compareData =~ s/kernel uptime.*/masked/g;

    if ($data eq $compareData)
    {
        return "true";
    }
    elsif ( $logLevel eq "0" )
    {
        $data =~ s/([^\x20-\x7F])/"[" . ord($1) . "]"/eg;
        $compareData =~ s/([^\x20-\x7F])/"[" . ord($1) . "]"/eg;
        return "false comparison:\n    data '$data'\ncompared to '$compareData'";
    }
    else
    {
        return "false";
    }
}

#! /usr/local/bin/perl

sub compare
{
    my($data,$compareData,$logLevel) = @_;

    $data        =~ s/(\n\s*)\d+/$1 xxx/gm;
    $compareData =~ s/(\n\s*)\d+/$1 xxx/gm;

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

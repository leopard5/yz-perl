#! /usr/local/bin/perl

sub compare
{
	my($data,$compareData,$logLevel) = @_;

	if ($data =~ /Neighbor.*V.*AS.*MsgRcvd/)
	{
		$data =~ s/BGP table version is [\d]+, main routing table version [\d]+//g;
		$data =~ s/[\d]+ network entries and [\d]+ paths using [\d]+ bytes of memory//g;
		$data =~ s/(\S+) +(\d+) +(\d+) +[\d]+ +[\d]+ +[\d]+ +[\d]+ +[\d]+ +[\S]+ +(\S+)/$1 $2 $3 xxx xxx $4/g;
	
	}
	else
	{
		$data =~ s/(via \S+, )\S+(,[\S\s]+?)(\n|$)/$1xxx$2$3/g;
		$data =~ s/(is a summary,) [\S]+, ([\S\s]+?)(\n|$)/$1 xxx $2$3/g;
	}

	if ($data =~ /Neighbor.*V.*AS.*MsgRcvd/)
	{
		$compareData =~ s/BGP table version is [\d]+, main routing table version [\d]+//g;
		$compareData =~ s/[\d]+ network entries and [\d]+ paths using [\d]+ bytes of memory//g;
		$compareData =~ s/(\S+) +(\d+) +(\d+) +[\d]+ +[\d]+ +[\d]+ +[\d]+ +[\d]+ +[\S]+ +(\S+)/$1 $2 $3 xxx xxx $4/g;
	}
	else
	{
		$compareData =~ s/(via \S+, )\S+(,[\S\s]+?)(\n|$)/$1xxx$2$3/g;
		$compareData =~ s/(is a summary,) [\S]+, ([\S\s]+?)(\n|$)/$1 xxx $2$3/g;
	}

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

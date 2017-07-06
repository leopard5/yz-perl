#! /usr/local/bin/perl

# <<OID<sysUpTime>>>=1 days, 14:35:50.12
# result might look like: .1.3.6.1.2.1.1.3.0 = Timeticks: (16323831) 1 day, 21:20:38.31
# print cleanupUptime("<<OID<sysUpTime>>>=1 days, 14:35:50.12");
sub cleanupUptime
{
	my($result) = @_;

	$result =~ s/[\n\r]//g;
	if($result !~ /<<OID<\S*>>>=(.*)/)
	{
		$cleanResult = "Unable to determine device boot time.";
	}
	else
	{
		$result =~ s/<<OID<\S*>>>=(.*)/$1/g;
		$cleanResult = $result;
	}

	return $cleanResult;
}

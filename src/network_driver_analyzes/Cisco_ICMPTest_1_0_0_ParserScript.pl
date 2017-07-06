#! /usr/local/bin/perl

sub stripCarriageReturns
{
	my($rawdata) = @_;
	
	$rawdata =~ s/\r//g;
	
	return $rawdata;
}

sub removeMores
{
	my($rawdata) = @_;

	$rawdata = stripCarriageReturns($rawdata);
	$rawdata =~ s/--More--[\s\cH]\cH+//g;
	
	return $rawdata;
}

sub stripLastLine
{
	my($rawdata) = @_;
	
	@lines = split('\n', $rawdata);

	$#lines--;

	my($cleandata) = "";
	my($linecount) = 0;
	foreach $line (@lines)
	{
		if ($linecount == $#lines)
		{
			$cleandata .= "$line";
		}
		else
		{
			$cleandata .= "$line\n";
		}
		$linecount++;
	}
	
	return $cleandata;	
}

sub GetICMPResultAndStatus
{
	my($result,$testType) = @_;
	my(@array) = ( "Success", $result );

	$result = removeMores($result);
	$result = stripLastLine($result);
	
	$array[1] = $result;

	if ($testType eq "Ping")
	{
		if ($result !~ /is 100 percent/ && $result !~ / 0\% packet loss/)
		{
			$array[0] = "FailureWithErrorMessage";
		}elsif ($result =~ /Unrecognized host/)
		{
			$array[0] = "FailureWithErrorMessage";
		}	

		$result =~ s/ping (\S+)\n+//;
		$array[1] = $result;
	}
	else #traceroute
	{
		$array[0] = "Success"; #assume success

		if ($result !~ /(traceroute|[Tt]racing the route) +to \S+/)
		{
			$array[0] = "FailureWithErrorMessage";
		}
		elsif ($result =~ /\n +\d+ +\* +\* +\*\s*$/)
		{
			$array[0] = "FailureWithErrorMessage";
		}
		$result =~ s/traceroute \S+\n+//;
		$array[1] = $result;
	}

	return @array;
}

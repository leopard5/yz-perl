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
	$rawdata =~ s/[\s\cH]+ ?--More--[ \S]*[\s\cH]+/\n/g;
	
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
		if ($result !~ /Success rate is 100 percent/)
		{
			$array[0] = "FailureWithErrorMessage";
		}

		$result =~ s/ping (\S+)\n+//;
		$array[1] = $result;
	}

	return @array;
}

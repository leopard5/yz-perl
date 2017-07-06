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

sub stripFirstAndLastLine
{
	my($rawdata) = @_;

	$rawdata =~ s/^[\S ]*?\n//;

	if ($rawdata =~ /\n/)
	{
		$rawdata =~ s/\n+$//;
		$rawdata =~ s/\n[\S ]*$//;
	}
	else
	{ # single line case - just blank the entire thing
		$rawdata = "";
	}

	return $rawdata;
}

sub GetCustomActionsResultAndStatus
{
	my($result,$mode) = @_;
	my(@array) = ( "Success", $result );

	$result = removeMores($result);
	$result = stripFirstAndLastLine($result);

	$array[1] = $result;

	return @array;
}

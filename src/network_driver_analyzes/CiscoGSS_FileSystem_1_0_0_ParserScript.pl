#! /usr/local/bin/perl

sub GetFileSystemInfo
{
	my($config) = @_;
	my(@array) = ();
	my($count) = 0;
	my($foundFiles) = 0;

	# The filesystem is unix-like; not much of interest except for the total/free space-stats.

	if ($config =~ /User space\(\/\)\s+(\d+) MB\s+(\d+) MB\s+(\d+) MB\s+/) {
		$total = $1;
		$used  = $2;
		$free  = $3;
		
		$array[$count] = "TotalMem";
		$array[$count+1] = "/";
		$array[$count+2] = $total * 1024 * 1024;
		$count += 3;

		$array[$count] = "FreeMem";
		$array[$count+1] = "/";
		$array[$count+2] = $free * 1024 * 1024;
		$count += 3;
	}

	return @array;
}

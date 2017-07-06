#! /usr/local/bin/perl

sub GetFileSystemInfo
{
	my($config) = @_;
	my(@array) = ();
	my($count) = 0;
	my($foundFiles) = 0;

	my $IGNORE_LOCATION = "(nvram|zflash)"; # Regexp of locations to ignore
	pos($config) = 0;

	while($config =~ /(\# dir \S+:?)/gc){
		$start = pos($config) - length($1);

		if($config =~ /(\# dir)/gc)
		{
			$end = pos($config) - length($1);
			pos($config) = $end;
			$subConfig = substr($config, $start, $end - $start);
		}
		else
		{
			$subConfig = substr($config, $start);
		}
		
		if($subConfig =~ /\# dir (\S+:?)/)
		{
			$location = $1;
			$location =~ s/\/$//;

			# Do not return data for the nvram filesystem
			next if $location =~ /$IGNORE_LOCATION/; 

			if(($subConfig =~ /(\d+) bytes available/)||($subConfig =~ /(\d+) total bytes/))
			{
				$totalMem = $1;

				$array[$count] = "TotalMem";
				$array[$count+1] = $location;
				$array[$count+2] = $totalMem;
				$count += 3;
			}

			if($subConfig =~ /(\d+) bytes free/)
			{
				$freeMem = $1;

				$array[$count] = "FreeMem";
				$array[$count+1] = $location;
				$array[$count+2] = $freeMem;
				$count += 3;

			}

			# Store the values for fileName and fileSize in a list: file1, file1_size, file2, file2_size {, ...}
			pos($subConfig) = 0;
			while($subConfig =~ /(\d+) +\S+ \d+ [\d\:]+ \d+ (\S+)/gc)
			{
				$foundFiles = 1;
				$fileSize = $1;
				$fileName = $2;

				$array[$count] = "Files";
				$array[$count+1] = $location;
				if($array[$count+2])
				{
					$array[$count+2] = $array[$count+2] . ",$fileName, $fileSize";
				}
				else
				{
					$array[$count+2] = "$fileName, $fileSize";
				}
			}
			$count += 3 if $foundFiles;
		}

	}

	return @array;
}


#! /usr/local/bin/perl

sub GetFileSystemInfo
{
	my($config) = @_;
	my(@array) = ();
	my($count) = 0;
	my($foundFiles) = 0;

	my $IGNORE_LOCATION = "(nvram|zflash)"; # Regexp of locations to ignore
	pos($config) = 0;

	while($config =~ /(Directory of \S+:?)/gc){
		$start = pos($config) - length($1);

		if($config =~ /(Directory of)/gc)
		{
			$end = pos($config) - length($1);
			pos($config) = $end;
			$subConfig = substr($config, $start, $end - $start);
		}
		else
		{
			$subConfig = substr($config, $start);
		}
		
		# Parse our information; location, FreeMem, TotalMem, Files, FileSize
		# Directory of bootflash:/
		#
		# No files in directory
		#
		# 7602176 bytes total (7602176 bytes free)
		#
		#
		# Directory of slot0:/
		#
		#   1  -rw-     8136948   Jan 30 2000 05:49:27  c5rsm-jsv-mz.120-27.bin
		#
		#   16384000 bytes total (8246924 bytes free)
		$foundFiles = 0;
		if($subConfig =~ /Directory of (\S+:?)(\/\S+\/)?/)
		{
			$location = $1;
			($location,$subdir) = split(/:/,$location,2);
			$location = $location . ":" if ($location !~ /:$/);

			# Do not return data for the nvram filesystem
			next if $location =~ /$IGNORE_LOCATION/; 

			if($subConfig =~ /(\d+) bytes total \((\d+) bytes free/)
			{
				$totalMem = $1;
				$freeMem  = $2;

				$totalmem{$location} = $totalMem;
				$freemem{$location} = $freeMem;
			}

			# Store the values for fileName and fileSize in a list: file1, file1_size, file2, file2_size {, ...}
			pos($subConfig) = 0;
			while($subConfig =~ /\d+ +(\S)\S+ +(\d+) +[\S ]+ +(\S+)/gc)
			{
				$foundFiles = 1;
				$directory = $1;
				$fileSize = $2;
				$fileName = $3;

				## Do not display directories
				next if ($directory eq "d");

				$fileName =~ s/^\///; # bug 155527

				if ($subdir ne "/") {
					$fileName = $subdir.$fileName;
				}

                                ## Commenting out next line because files within brackets are deleted files - bug 157144
                                # $fileName =~ s/[\[\]]//g; # Seen on the 831; bug 8661

                                ## bug 157144 - filenames within brackets are deleted files and should not be shown in the filesystem diagnostic

                                if ($fileName !~ /\[\S+\]/) {
					if($files{$location})
					{
						$files{$location} = $files{$location} . ",$fileName, $fileSize";
					} else {
						$files{$location} = "$fileName, $fileSize";
					}
                                }
                        }
			#$count += 3 if $foundFiles;
		}

	}

		foreach $loc (keys(%totalmem))
		{
			
				$array[$count] = "TotalMem";
				$array[$count+1] = $loc;
				$array[$count+2] = $totalmem{$loc};
				$count += 3;
		}

		foreach $loc (keys(%freemem))
		{
				$array[$count] = "FreeMem";
				$array[$count+1] = $loc;
				$array[$count+2] = $freemem{$loc};
				$count += 3;
		}

		foreach $loc (keys(%files))
		{
                                $array[$count] = "Files";
                                $array[$count+1] = $loc;
				$array[$count+2] = $files{$loc};
				$count +=3;
		}


	return @array;
}

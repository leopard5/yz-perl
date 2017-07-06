#! /usr/local/bin/perl

sub GetFileSystemInfo
{
	my($config) = @_;
	my(@array) = ();
	my($count) = 0;
	my($foundFiles) = 0;
	my $subConfig = "";

	my $IGNORE_LOCATION = "(nvram|zflash)"; # Regexp of locations to ignore
	pos($config) = 0;

	while($config =~ /(dir \S+:)/gc){
		$start = pos($config) - length($1);

		if($config =~ /\#/gc)
		{
			$end = pos($config);
			pos($config) = $end;
			$subConfig = substr($config, $start, $end - $start);
		}
		else
		{
			$subConfig = substr($config, $start);
		}
		
		# rs-cisco9509-01# dir bootflash:
		#         702     Jan 01 08:04:55 1980  license15.lic
		#       12288     Jan 01 08:01:04 1980  lost+found/
		#    19423513     Jan 01 08:04:28 1980  m9000-ek9-asm-sfn-mz.1.3.3.bin
		#    14447104     Apr 26 10:09:08 2007  m9500-sf1ek9-kickstart-mz.2.0.2b.bin
		#    14618624     Jan 27 11:05:59 2007  m9500-sf1ek9-kickstart-mz.3.0.2b.bin
		#    51369697     Apr 26 10:10:49 2007  m9500-sf1ek9-mz.2.0.2b.bin
		#    69325024     Jan 27 11:06:46 2007  m9500-sf1ek9-mz.3.0.2b.bin
		#
		# Usage for bootflash://sup-local
		#   183612416 bytes used
		#      947200 bytes free
		#   184559616 bytes total
		# rs-cisco9509-01#
		$foundFiles = 0;
		if($subConfig =~ /dir (\S+:)/)
		{
			$location = $1;
			$location =~ s/\/$//;

			# Do not return data for the nvram filesystem
			next if $location =~ /$IGNORE_LOCATION/; 

			if($subConfig =~ /(\d+) bytes free\n +(\d+) bytes total/)
			{
				$totalMem = $2;
				$freeMem  = $1;

				$array[$count] = "TotalMem";
				$array[$count+1] = $location;
				$array[$count+2] = $totalMem;
				$count += 3;

				$array[$count] = "FreeMem";
				$array[$count+1] = $location;
				$array[$count+2] = $freeMem;
				$count += 3;

			}

			# Store the values for fileName and fileSize in a list: file1, file1_size, file2, file2_size {, ...}
			pos($subConfig) = 0;
			while($subConfig =~ /(\d+)\s+\S+\s+\d\d\s+\d\d:\d\d:\d\d \d\d\d\d\s+(\S+)/gc)
			{
				$foundFiles = 1;
				$fileSize = $1;
				$fileName = $2;

                                ## Commenting out next line because files within brackets are deleted files - bug 157144
                                # $fileName =~ s/[\[\]]//g; # Seen on the 831; bug 8661

                                ## bug 157144 - filenames within brackets are deleted files and should not be shown in the filesystem diagnostic

                                if ($fileName !~ /\[\S+\]/) {
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
			}
			$count += 3 if $foundFiles;
		}

	}

	return @array;
}


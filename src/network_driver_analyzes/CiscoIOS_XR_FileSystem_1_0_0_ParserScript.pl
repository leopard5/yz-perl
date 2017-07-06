#! /usr/local/bin/perl

sub GetFileSystemInfo
{
	my($config) = @_;
	my(@array) = ();
	my($count) = 0;
	my($foundFiles) = 0;

	my (@files);

	pos($config) = 0;

	while($config =~ /ATA PCMCIA card at disk (\d+)/gc) {
		push(@requiredlocations, "disk".$1.":");
	}

	pos($config) = 0;

	if($config =~ /(Package active on node \S+:?)/gc){
		$start = pos($config) - length($1);

		if($config =~ /(Package active on node)/gc)
		{
			$end = pos($config) - length($1);
			pos($config) = $end;
			$subConfig = substr($config, $start, $end - $start);
		}
		else
		{
			$subConfig = substr($config, $start);
		}
		
		$foundFiles = 0;
		if($subConfig =~ /Package active on node (\S+:?)/)
		{
			pos($subConfig) = 0;
			while($subConfig =~ /[\S ]+?at (\S+?:)(\S+)/gc)
			{
				$location = $1;
				$fileName = $2;

				push (@files, $location.$fileName);

				$found{$location} = 1;
				
				if ($files{$location}) {
					$files{$location} = $files{$location} . ",$fileName, $fileSize";
				} else {
					$files{$location} = "$fileName, $fileSize";
				}
			}

		}

	}

	pos ($config) = 0;
	while ($config =~ /\n +(\S+?:)(\S+)/gc)
	{
		$location = $1;
		$fileName = $2;
		
		$found = 0;
		foreach (@files) {
			$found = 1 if ($_ eq $location.$fileName);
		}

		if ($found == 0)
		{
			if ($files{$location}) {
				$files{$location} = $files{$location} . ",$fileName, $fileSize";
			} else {
				$files{$location} = "$fileName, $fileSize";
			}
		}
	}
			
	foreach(keys(%files))
	{
		$array[$count] = "Files";
		$array[$count+1] = $_;
		$array[$count+2] = $files{$_};
		$count += 3;
	}


	foreach(@requiredlocations) {
		if($found{$_} != 1) {
			$array[$count] = "Files";
			$array[$count+1] = $_;
			$array[$count+2] = "";
			$count += 3;
		}
	}


	return @array;
}

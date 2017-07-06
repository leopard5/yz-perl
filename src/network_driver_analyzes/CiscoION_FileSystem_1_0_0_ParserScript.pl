#! /usr/local/bin/perl

sub GetFileSystemInfo
{
	my($config) = @_;
	my(@array) = ();
	my($count) = 0;
	my($foundFiles) = 0;

	pos($config) = 0;

	while($config =~ /(B|P|MP) +\*? +Active +(\S+:\/\S+?)(\/\S+)/gc){
		
		$location = $2;
		$fileName = $3;
		$fileSize = "";

		if($locations{$location})
		{
			$locations{$location} = $locations{$location} . ",$fileName, $fileSize";
		}
		else
		{
			$locations{$location} = "$fileName, $fileSize";
		}

	}

	foreach(keys(%locations)) {
		
		$location = $_;

		$array[$count] = "Files";
		$array[$count+1] = $location;
		$array[$count+2] = $locations{$location};

		$count += 3;
	}

	return @array;
}

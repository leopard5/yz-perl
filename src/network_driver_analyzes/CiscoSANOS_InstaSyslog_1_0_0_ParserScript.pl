#! /usr/local/bin/perl

sub GetLevel
{	
	return "6";	
}

sub GetLevelSetting
{
	return "global";
}

sub GetLevelOrder
{
	return ("0", "1", "2", "3", "4", "5", "6", "7");
}

sub GetLoggingServers
{
	my($config) = @_;
	my(@array) = ();

	$level = "6";
	if ($config =~ /logging trap (\S+)/)
	{
		$level = $1;
	}

	while ($config =~ /logging server ([\S ]+)/gc)
	{
		foreach (split(/ /,$1)) {
			$array[$count] = $_;
			$array[$count+1] = $level;
			$count = $count + 2;	
		}
	}
	
	return @array;	
}

sub GetDirectScript
{
	$script = "logging server <ip>\n";
	$script = $script . "logging level all 6\n";
	return $script; 
}

sub GetRelayScript
{
	$script = $script . "logging level all 6\n";
	return $script; 
}


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

	while ($config =~ /logging host (\d+.\d+.\d+.\d+)/gc)
	{
		$array[$count] = $1;
		$array[$count+1] = $level;
		$count = $count + 2;	
	}
	
	return @array;	
}

sub GetDirectScript
{
	$script = "logging host <ip>\n";
	$script = $script . "logging trap 6\n";
	$script = $script . "logging enable";
	return $script; 
}

sub GetRelayScript
{
	$script = "logging trap 6\n";
	$script = $script . "logging enable";
	return $script; 
}


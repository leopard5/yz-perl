#! /usr/local/bin/perl

sub GetLevel
{	
	return "informational";	
}

sub GetLevelSetting
{
	return "global";
}

sub GetLevelOrder
{
	return ("emergencies", "alerts", "critical", "errors", "warnings", "notifications", "informational", "debugging");
}

sub GetLoggingServers
{
	my($config) = @_;
	my(@array) = ();

	$level = "informational";
	if ($config =~ /logging trap (\S+)/)
	{
		$level = $1;
	}

	while ($config =~ /logging (\d+.\d+.\d+.\d+)/gc)
	{
		$array[$count] = $1;
		$array[$count+1] = $level;
		$count = $count + 2;	
	}
	# logging host ipv6 FC00::188
	while ($config =~ /logging host ipv6 ([a-fA-F0-9:\.]+)/gc)
	{
		$array[$count] = $1;
		$array[$count+1] = $level;
		$count = $count + 2;	
	}
	
	return @array;	
}

sub GetDirectScript
{
	$script = "logging <ip>\n";
	$script = $script . "logging trap informational\n";
	$script = $script . "logging on";
	return $script; 
}

sub GetRelayScript
{
	$script = "logging trap informational\n";
	$script = $script . "logging on";
	return $script; 
}


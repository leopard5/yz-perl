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
	return ("emergencies", "alert", "critical", "errors", "warnings", "notifications", "informational", "debugging");
}

sub GetLoggingServers
{
	my($config) = @_;
	my(@array) = ();

	$level = "informational";
	if ($config =~ /logging host priority (\w+)/)
	{
		$level = lc($1);
	}

	while ($config =~ /logging host ip (\d+.\d+.\d+.\d+)/gc)
	{
		$array[$count] = $1;
		$array[$count+1] = $level;
		$count = $count + 2;	
	}
	
	return @array;	
}

sub GetDirectScript
{
	$script = "logging host ip <ip>\n";
	$script = $script . "logging host priority informational\n";
	$script = $script . "logging host enable";
	return $script; 
}

sub GetRelayScript
{
	$script = "logging host priority informational\n";
	$script = $script . "logging host enable";
	return $script; 
}


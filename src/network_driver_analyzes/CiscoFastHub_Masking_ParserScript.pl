#! /usr/local/bin/perl

sub maskPasswords
{
	my($config) = @_;

	$config =~ s/level (\d+) password: \S+/"level $1 password: xxx"/ge;
	$config =~ s/(Read|Write) community string: \S+/$1 community string: xxx/g;
	
	# Attempt to mask the limited user password... it's the first line in the config after the opening comment lines
	$config =~ s/^([!\s]+)(\S+)/$1xxx/;
	
	return $config;
}

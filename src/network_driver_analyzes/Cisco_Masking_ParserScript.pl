#! /usr/local/bin/perl

sub maskPasswords
{
	my($config) = @_;

	# Remove large block of text from config for crypto ca certificate chain definitions
	if($config =~ /certificate ca \S+[\S\s]+ +quit/)
	{
		$config =~ s/(certificate ca \S+)[\S\s]+( +quit)/$1\nxxx\n$2/g;
	}

	
	my $finalconfig = "";
	my (@lines) = split('\n', $config);

	foreach $line (@lines)
	{
		# community strings
		$line =~ s/(snmp-server community )\S+( \d+)?( view \w+)?( [Rr][OoWw])( \d+)?/$1xxx$2$3$4$5/g;
		##
		# cisco acns
		$line =~ s/(snmp-server community )\S+(\s+group \S+.*?)?/$1xxx$2/g;
		
		
		# host community strings
		my $find = "";
		if ($line =~ /(snmp-server host +\S+ )(\S+)/gc)
		{
			$find = $1;

			$test = $2;
			if ($test eq "inform")
			{
				if ($line =~ /\G( +)(\S+)/gc)
				{
					$find .= $test . $1;
					$test = $2;
				}
			}

			if ($test eq "version")
			{
				if ($line =~ /\G(( 1 )|( 2c )|( 3 (no)?auth ))(\S+)/gc)
				{
					$find .= $test . $1;
				}
			}

			pos($line) = 0;
			$repl = "$find" . "xxx";
			$line =~ s/($find)\S+/$repl/;
		}
		# rmon event community strings
		$line =~ s/rmon event( \d+)( log)? trap \S+/rmon event$1$2 trap xxx/g;

		# some devices have default strings
		$line =~ s/no snmp-server community (\S+)/no snmp-server community xxx/g;

		# enable passwords
		$line =~ s/enable ((secret)|(password))( level \d+)?( \d)?.*/enable $1$4$5 xxx/g;
		# user passwords
		$line =~ s/(username[\S ]+?password \d )[\S ]+/$1xxx/g;
		# line passwords
		$line =~ s/(^\s+password )[\S ]+/$1xxx/g;
		# additional passwords
		$line =~ s/password (\d+) \S+/password $1 xxx/g;

		# bgp neighbor passwords
		$line =~ s/neighbor (\w+) password( \d)? [\S ]+?$/neighbor $1 password$2 xxx/g;

		# ntp authentication keys
		$line =~ s/ntp authentication-key( \d+ \S+ )\S+ (\d+)/ntp authentication-key$1xxx $2/g;
		# ospf authentication keys
		$line =~ s/ip ospf authentication-key \S+/ip ospf authentication-key xxx/g;
		$line =~ s/ip ospf message-digest(-| )key (\d+) md5 (\d+) [\S]+/ip ospf message-digest key $2 md5 $3 xxx/g;
		# tacacs server key
		$line =~ s/tacacs-server key (\d+ )?\S+/tacacs-server key $1xxx/g;
		$line =~ s/tacacs-server host (\S+) key \S+/tacacs-server host $1 key xxx/g;
		# standby authentication keys
		$line =~ s/standby( \d+)? authentication(\s+)[\S\s]+?$/standby$1 authentication$2xxx/g;
		# config keys
		$line =~ s/key config-key( [123] )\S+/key config-key$1xxx/g;
		# radius server key
		if ($line =~ /radius.* key \d \S+/)
			{
				$line =~ s/(radius.* key \d+) \S+/$1 xxx/;		
			}
		else
			{
				$line =~ s/(radius.* key) \S+/$1 xxx/;
			}

		# crypto keys
		$line =~ s/crypto isakmp key [\S]+ address (\S+)/crypto isakmp key xxx address $1/g;
		$line =~ s/crypto ca trustpoint [\S]+/crypto ca trustpoint xxx/g;
		$line =~ s/crypto ca certificate chain [\S]+/crypto ca certificate chain xxx/g;
		$line =~ s/certificate ca [\S]+$/certificate ca xxx/g;
		$line =~ s/set security-association (\S+) esp (\S+) cipher [\S]+/set security-association $1 esp $2 cipher xxx/g;
		$line =~ s/set security-association (\S+) ah (\d+) [\S]+/set security-association $1 ah $1 xxx/g;
		$line =~ s/l2tp tunnel password (\d+) password [\S]+/l2tp tunnel password $1 password xxx/g;
		$line =~ s/key-string (\d+) [\S]+/key-string $1 xxx/g;

		# Aironet 1100 IOS device
		$line =~ s/encryption key (\d+) size (\S+) (\d+) (\S+) ([\S]+)*/encryption key $1 size $2 $3 xxx $5/g;

		# snmp-server user limited default-role auth md5 0x59acbe924178712dae4859c078d3e08d priv 0x59acbe924178712dae4859c078d3e08d localizedkey
		$line =~ s/(auth (md5|sha)) \S+/$1 xxx/g;
		$line =~ s/ priv \S+\s*\S*/ priv xxx/g;
		
		$line =~ s/snmp-server user \S+/snmp-server user xxx/g;
		
		$finalconfig .= $line . "\n";
	}

	return $finalconfig;
}

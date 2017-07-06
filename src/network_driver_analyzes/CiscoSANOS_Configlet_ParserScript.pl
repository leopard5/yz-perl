#! /usr/local/bin/perl

sub findBlock
{
	my($config, $startBlock, $endBlock, $helper) = @_;
	
	my $interface_config = "";
	
	while ($config =~ /\n\s*\n(interface $startBlock[\S\s]*?)(\n\s*\n|\ninterface|\n#)/g)
	{	
		$interface_config = "$1";
	}
		
	return $interface_config;
}

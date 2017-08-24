#!/usr/bin/perl

use strict;
use Digest::MD5;

my $file_1 = shift || '/etc/passwd';
open( FILE, $file_1 ) or die "Can't open '$file_1': $!";
binmode(FILE);

my $md5 = Digest::MD5->new;
while (<FILE>) {
    $md5->add($_);
}
close(FILE);
print $md5->hexdigest, " $file_1\n";


###另外一种实现方法

my $file_2 = shift || '/etc/passwd';
open( FH, $file_2 ) or die "Can't open '$file_2': $!";
binmode(FH);

print Digest::MD5->new->addfile(*FH)->hexdigest, " $file_2\n";
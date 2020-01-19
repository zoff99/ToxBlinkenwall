#!/usr/bin/perl

$ip = @ARGV[0];
chomp($ip);
$bi = pack "C4", split('\.', $ip);
print "$bi";

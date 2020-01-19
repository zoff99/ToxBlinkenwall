#!/usr/bin/perl

$port = @ARGV[0];
chomp($port);
$bi = pack "S1", $port;
print "$bi";

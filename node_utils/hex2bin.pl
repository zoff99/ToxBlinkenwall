#!/usr/bin/perl

$hex = @ARGV[0];
chomp($hex);
print pack "H*", $hex;

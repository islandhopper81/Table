#!/usr/bin/evn perl

use strict;
use warnings;

my @headers = (0..99);

open my $OUT, ">", "biger_data.csv";
print $OUT join(",", @headers) . "\n";

my $count = 0;
my @vals = (100..199);
while ( $count < 100000 ) {
	print $OUT join(",", @vals) . "\n";
	
	$count ++;
}
close($OUT);

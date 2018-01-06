#!/usr/bin/evn perl

use Table;

use strict;
use warnings;

my $usage = "$0 <tbl file>\n";

my $tbl_file = shift or die $usage;

my $table = Table->new();
$table->load_from_file($tbl_file);

print "Done\n";

print "col_count: ", $table->get_col_count(), "\n";
print "row_count: ", $table->get_row_count(), "\n";
print "at Cluster_135703, 2576861325: ", $table->get_value_at("Cluster_135703", "2576861325"), "\n";

use strict;
use warnings;

use Test::More tests => 29;
use Test::Exception;
use MyX::Table;

# others to include
use File::Temp qw/ tempfile tempdir /;

BEGIN { use_ok('Table::Numeric' ); }
BEGIN { use_ok('MyX::Table'); }
BEGIN { use_ok('Table::Iter'); }
BEGIN { use_ok('MyX::Table::Iter'); }



# helper subroutines
sub _make_tbl_file;



###############
# Begin Tests #
###############

# Test constructor
my $table = undef;
lives_ok( sub { $table = Table::Numeric->new() },
         "expected to live" );

# load in the file
# this test is also done in Table.t but I want to double check it here
# test load_from_file
{
    # make a temp file
    my($fh, $filename) = tempfile();
    
    throws_ok( sub{ $table->load_from_file() },
              'MyX::Generic::Undef::Param', "load_from_file() - caught" );
    throws_ok( sub{ $table->load_from_file("blah") },
              'MyX::Generic::DoesNotExist::File', "load_from_file(blah) - caught" );
    throws_ok( sub{ $table->load_from_file($filename) },
              'MyX::Generic::File::Empty', "load_from_file(empty file) - caught" );
    
    _make_tbl_file($fh);
    lives_ok( sub{ $table->load_from_file($filename, ",") },
             "expected to live -- load_from_file()" );
    
    # check the names to make sure they were set correctly
    is_deeply( $table->get_row_names(), ["M", "N", "O", "P", "Q"],
              "load_from_file -- look at row names" );
    is_deeply( $table->get_col_names(), ["A", "B", "C", "D", "E"],
              "load_from_file -- look at col names" );
    
    # make sure the row_names_header is undefined
    is( $table->get_row_names_header(), undef,
       "load_from_file -- row names header" );
    is( $table->has_row_names_header(), 0,
       "load_from_file -- has_row_names_header" );
}

# test max
{
    lives_ok( sub{$table->max()},
              "expected to live -- max()" );
    
    is( $table->max(), 5, "max() == 5" );
}

# test min
{
    lives_ok( sub{$table->min()},
              "expected to live -- min()" );
    
    is( $table->min(), 0, "min() == 0" );
}

# test aggregate
{
    throws_ok( sub{ $table->aggregate() },
              'MyX::Generic::Undef::Param', "aggregate() - caught" );
    
    throws_ok( sub{ $table->aggregate("blah") },
               'MyX::Generic::Ref::UnsupportedType', "aggregate(blah) - caught" );
    
    # too short
    my @bad1 = ("g1", "g2", "g2", "g1");
    throws_ok( sub{ $table->aggregate(\@bad1) },
               'MyX::Table::BadDim', "aggregate(too short) - caught" );
    
    # too long
    my @bad2 = ("g1", "g2", "g2", "g1", "g1", "g1");
    throws_ok( sub{ $table->aggregate(\@bad2) },
               'MyX::Table::BadDim', "aggregate(too long) - caught" );
    
    my @good1 = ("g1", "g2", "g2", "g1", "g1");
    my $new_tbl;
    my @g1_agg = (10, 13, 11, 7, 7);
    my @g2_agg = (5, 3, 3, 9, 9);
    lives_ok( sub{ $new_tbl = $table->aggregate(\@good1) },
              "expected to live -- aggregate(good1)" );
    
    is( $new_tbl->get_row_count(), 2, "get_row_count of agg table");
    my @row_names = ("g1", "g2");
    is_deeply( $new_tbl->get_row_names(), \@row_names, "check agg tbl row names" );
    is_deeply( $new_tbl->get_row("g1"), \@g1_agg, "check agg tbl row g1" );
    is_deeply( $new_tbl->get_row("g2"), \@g2_agg, "check agg tbl row g2" );
    
    my @good2 = ("g3", "g4", "g3", "g3", "g3");
    my @g3_agg = (13, 16, 11, 11, 11);
    my @g4_agg = (2, 0, 3, 5, 5);
    lives_ok( sub{ $new_tbl = $table->aggregate(\@good2) },
              "expected to live -- aggregate(good2)" );
    
    is_deeply( $new_tbl->get_row("g3"), \@g3_agg, "check agg tbl row g3" );
    is_deeply( $new_tbl->get_row("g4"), \@g4_agg, "check agg tbl row g4" );
}


###############
# Helper Subs #
###############
sub _make_tbl_file {
    my ($fh) = @_;
    
    # there is a text version of this tree at the bottom
    
    my $str = "A,B,C,D,E
M,0,3,3,5,5
N,2,0,3,5,5
O,3,3,0,4,4
P,5,5,4,0,2
Q,5,5,4,2,0";

    print $fh $str;
    
    close($fh);
    
    return 1;
}

sub _make_tbl_file2 {
        my ($fh) = @_;
    
    # this is basically the same as the function above, but it creates the table
    # in the second valid format.  This format includes a name for the row names
    # column.
    
    # there is a text version of this tree at the bottom
    
    my $str = "RowNames,A,B,C,D,E
M,0,3,3,5,5
N,2,0,3,5,5
O,3,3,0,4,4
P,5,5,4,0,2
Q,5,5,4,2,0";

    print $fh $str;
    
    close($fh);
    
    return 1;
}

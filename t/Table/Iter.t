use strict;
use warnings;

use Test::More tests => 20;
use Test::Exception;
use MyX::Table;
use Table;

# others to include
use File::Temp qw/ tempfile tempdir /;

BEGIN { use_ok( 'Table::Iter'); }


# helper subroutines
sub _make_tbl_file;



###############
# Begin Tests #
###############

# create a Table object to iterate over
my($fh, $filename) = tempfile();
_make_tbl_file3($fh);
my $tbl = Table->new();
$tbl->load_from_file($filename, ",");


# Test constructor
my $tbl_iter = undef;
throws_ok( sub{ $tbl_iter = Table::Iter->new() },
          'MyX::Generic::Undef::Param', "new() - caught" );
lives_ok( sub { $tbl_iter = Table::Iter->new({table => $tbl}) },
         "expected to live -- new(tbl)" );

# test get_current_row
{
    is( $tbl_iter->get_current_row(), 0, "get_current_row() -- 0" );
}

# test get_current_col
{
    is( $tbl_iter->get_current_col(), -1, "get_current_col() -- -1" );
}

# test has_next_value
{
    is( $tbl_iter->has_next_value(), 1, "has_next_value() -- T" );
}

# test get_next_value
{
    # look at each of the table values individually
    is( $tbl_iter->get_next_value(), 0, "get_next_value() -- at (0,0)" );
    is( $tbl_iter->get_current_row(), 0, "get_next_value() -- current row: 0" );
    is( $tbl_iter->get_current_col(), 0, "get_next_value() -- current col: 0" );
    
    # get the rest of the row
    is( $tbl_iter->get_next_value(), 3, "get_next_value() -- at (0,1)" );
    is( $tbl_iter->get_next_value(), 3, "get_next_value() -- at (0,2)" );
    
    # now start on row 2
    is( $tbl_iter->get_next_value(), 2, "get_next_value() -- at (1,0)" );
    is( $tbl_iter->get_current_row(), 1, "get_next_value() -- current row: 1" );
    is( $tbl_iter->get_current_col(), 0, "get_next_value() -- current col: 0" );
    
    is( $tbl_iter->get_next_value(), 0, "get_next_value() -- at (1,1)" );
    is( $tbl_iter->get_next_value(), 3, "get_next_value() -- at (1,2)" );
    
    throws_ok( sub{ $tbl_iter->get_next_value() },
              "MyX::Table::Iter::EmptyTable",
              "get_next_value() -- empty table" );
    
    # now the iterator is at the last point; make sure has_next_value is false
    is( $tbl_iter->has_next_value(), 0, "has_next_value() -- should be false" );
}

# what happens when the table is empty
{
    my $empty_tbl = Table->new();
    my $empty_iter;
    
    lives_ok( sub { $empty_iter = Table::Iter->new({table => $empty_tbl}) },
         "expected to live -- new($empty_tbl)" );
    
    is( $empty_iter->has_next_value(), 0, "has_next_value() -- empty table" );
    
    # it should throw an error when I try to get the next value by calling the
    # get_next_value function
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

sub _make_tbl_file3 {
    my ($fh) = @_;
    
    # this is basically the same as the function above, but it creates a smaller
    # table
    
    my $str = "A,B,C
M,0,3,3
N,2,0,3";

    print $fh $str;
    
    close($fh);
    
    return 1;
}
use strict;
use warnings;

use Test::More tests => 401;
use Test::Exception;
use MyX::Table;
use UtilSY qw(:all);
use Log::Log4perl qw(:easy);
use Log::Log4perl::CommandLine qw(:all);

# others to include
use File::Temp qw/ tempfile tempdir /;

BEGIN { use_ok('Table' ); }
BEGIN { use_ok('MyX::Table'); }
BEGIN { use_ok('Table::Iter'); }
BEGIN { use_ok('MyX::Table::Iter'); }



# helper subroutines
sub _make_tbl_file_c1;
sub _make_tbl_file_c2;
sub _make_tbl_file_c3;
sub _make_tbl_file_c4;
sub _make_tbl_file_c5;
sub _make_tbl_file_missing_vals;
sub _make_tbl_file_c1_comm;
sub _make_tbl_file_c4_sb;

# get a logger singleton
my $logger = get_logger();



###############
# Begin Tests #
###############

# Test constructor
my $table = undef;
lives_ok( sub { $table = Table->new() },
         "expected to live" );

# test get_row_count
{
    is( $table->get_row_count(), 0, "get_row_count");
}

# test get_col_count
{
    is( $table->get_col_count(), 0, "get_col_count");
}

# test get_row_names_header when it is undef
{
    is( $table->get_row_names_header(), undef, "get_row_names_header(undef)");
}

# test _set_row_names_header
# AND test has_row_names_header
{
    is( $table->has_row_names_header, 0, "has_row_names_header(FALSE)" );
    
    lives_ok( sub { $table->_set_row_names_header("rows") },
             "expect to live");
    is( $table->get_row_names_header, "rows", "get_row_names_header(undef)");
    is( $table->has_row_names_header, 1, "has_row_names_header(TRUE)" );
    
    # reset the table to not have a row header
    $table->_set_row_names_header(undef);
}

# test _set_row_count
{
    throws_ok( sub { $table->_set_row_count(); },
          'MyX::Generic::Undef::Param', "_set_row_count() - caught" );
    throws_ok( sub { $table->_set_row_count("a"); },
          'MyX::Generic::Digit::MustBeDigit', "_set_row_count(a) - caught" );
    throws_ok( sub { $table->_set_row_count(-1); },
          'MyX::Generic::Digit::TooSmall', "_set_row_count(-1) - caught" );
    
    lives_ok( sub{ $table->_set_row_count(1) },
             "expected to live");
    
    is( $table->get_row_count(), 1, "_set_row_count(1)" );
}

# test _set_col_count
{
    throws_ok( sub { $table->_set_col_count(); },
          'MyX::Generic::Undef::Param', "_set_col_count() - caught" );
    throws_ok( sub { $table->_set_col_count("a"); },
          'MyX::Generic::Digit::MustBeDigit', "_set_col_count(a) - caught" );
    throws_ok( sub { $table->_set_col_count(-1); },
          'MyX::Generic::Digit::TooSmall', "_set_col_count(-1) - caught" );
    
    lives_ok( sub{ $table->_set_col_count(1) },
             "expected to live");
    
    is( $table->get_col_count(), 1, "_set_col_count(1)" );
}

# test _aref_to_href
{
    my $aref1 = ["a", "b", "c"];
    my $href1 = {"a" => 0, "b" => 1, "c" => 2};
    is_deeply( Table::_aref_to_href($aref1), $href1, "_aref_to_href -- 1" );
    
    my $aref2 = ["a", "a"];
    my $href2 = {"a" => 1};
    is_deeply( Table::_aref_to_href($aref2), $href2, "_aref_to_href -- 2" );
}

# test _set_col_names
{
    throws_ok( sub{ $table->_set_col_names(); },
          'MyX::Generic::Undef::Param', "_set_col_names() - caught" );
    
    my $names_aref = ["a", "b"];
    throws_ok( sub{ $table->_set_col_names($names_aref)},
              'MyX::Table::BadDim', "_set_col_names([a,b]) - caught" );
    
    $table->_set_col_count(2);
    throws_ok( sub{ $table->_set_col_names(["a", "a"]); },
              'MyX::Table::NamesNotUniq', "_set_col_names([a,a]) - caught" );
    
    lives_ok( sub{ $table->_set_col_names(["a", "b"]) },
             "expect to live");
}

# test get_col_names
{
    # remember at this point the column names are set to ["a", "b"] -- see
    # the test section _set_col_names
    
    is_deeply( $table->get_col_names(), ["a", "b"], "get_col_names" );
    is_deeply( $table->get_col_names(1), ["a", "b"], "get_col_names(by index)" );
}

# test _set_row_names
{
    throws_ok( sub{ $table->_set_row_names(); },
          'MyX::Generic::Undef::Param', "_set_row_names() - caught" );
    
    my $names_aref = ["a", "b"];
    throws_ok( sub{ $table->_set_row_names($names_aref)},
              'MyX::Table::BadDim', "_set_row_names([a,b]) - caught" );
    
    $table->_set_row_count(2);
    throws_ok( sub{ $table->_set_row_names(["a", "a"]); },
              'MyX::Table::NamesNotUniq', "_set_row_names([a,a]) - caught" );
    
    lives_ok( sub{ $table->_set_row_names(["a", "b"]) },
             "expect to live");
}

# test get_row_names
{
    # remember at this point the row names are set to ["a", "b"] -- see
    # the test section _set_row_names
    
    is_deeply( $table->get_row_names(), ["a", "b"], "get_row_names" );
    is_deeply( $table->get_row_names(1), ["a", "b"], "get_row_names(by index" );
}

# test _set_sep
{
    is( Table::_set_sep(","), ",", "_set_sep(,)" );
    is( Table::_set_sep(), "\t", "_set_sep()" );
}

# test _set_comm_char
{
    is( Table::_set_comm_char("#"), "#", "_set_comm_char(#)" );
    is( Table::_set_comm_char(), undef, "_set_comm_char()" );
}

# test _is_comment
{
    is( Table::_is_comment("not_a_comment", undef), 0, "_is_comment(no)" );
    is( Table::_is_comment("#comment", "#"), 1, "_is_comment(yes)" );
}

# test _is_skip_after
{
    is( Table::_is_skip_after(1, 4), 0, "_is_skip_after(4,1) -- no" );
    is( Table::_is_skip_after(4, 4), 0, "_is_skip_after(4,4) -- no" );
    is( Table::_is_skip_after(5, 4), 1, "_is_skip_after(4,5) -- yes" );
}

# test _is_skip_before
{
    is( Table::_is_skip_before(1, 4), 1, "_is_skip_before(4,1) -- yes" );
    is( Table::_is_skip_before(4, 4), 0, "_is_skip_before(4,4) -- no" );
    is( Table::_is_skip_before(5, 4), 0, "_is_skip_before(4,5) -- no" );
}

# test _has_col_headers
{
    is( Table::_has_col_headers(), 1, "_has_col_headers()" );
    is( Table::_has_col_headers(0), 0, "_has_col_headers(0)" );
    is( Table::_has_col_headers("F"), 0, "_has_col_headers(F)" );
}

# test _is_aref
{
    my $href = {"A" => 1, "B" => 2};
    throws_ok( sub{Table::_is_aref($href, "name")},
              'MyX::Generic::Ref::UnsupportedType', "_is_aref(href)" );
    
    my $aref = ["A", "B"];
    lives_ok( sub{ Table::_is_aref($aref, "name") },
             "execpted to live _is_aref");
}

# test load_from_file
{
    # There are 5 possible file formats that are accepted
    # 1. no col headers AND no row headers
    # 2. no column headers, has row names
	# 3. has column headers, no row names
	# 4. has column headers no header for row names, has row names
	# 5. has column headers with header for row names, has row names (default)
    
    # make a temp file
    my($fh, $filename) = tempfile();
    
    throws_ok( sub{ $table->load_from_file() },
              'MyX::Generic::Undef::Param', "load_from_file() - caught" );
    throws_ok( sub{ $table->load_from_file("blah") },
              'MyX::Generic::DoesNotExist::File', "load_from_file(blah) - caught" );
    throws_ok( sub{ $table->load_from_file($filename) },
              'MyX::Generic::File::Empty', "load_from_file(empty file) - caught" );
    
    #-------
    # Case 4
    #-------
    # case 4 is the default for many of the downstream test cases
    _make_tbl_file_c4($fh);
    
    lives_ok( sub{ $table->load_from_file($filename, ",") },
             "expected to live -- load_from_file($filename) -- Case 4" );

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
    
    #-------
    # Case 5
    #-------
    ($fh, $filename) = tempfile();
    _make_tbl_file_c5($fh);
     lives_ok( sub{ $table->load_from_file($filename, ",") },
             "expected to live -- load_from_file() -- Case 5" );
    
    # check the names to make sure they were set correctly
    is_deeply( $table->get_row_names(), ["M", "N", "O", "P", "Q"],
              "load_from_file -- look at row names in case 5" );
    is_deeply( $table->get_col_names(), ["A", "B", "C", "D", "E"],
              "load_from_file -- look at col names in case 5" );
    
    is( $table->get_row_names_header(), "RowNames",
       "load_from_file - row names header in case 5" );
    is( $table->has_row_names_header(), 1,
       "load_from_file -- has_row_names_header in case 5" );
    
    #-------
    # Case 3
    #-------
    ($fh, $filename) = tempfile();
    _make_tbl_file_c3($fh);
     lives_ok( sub{ $table->load_from_file($filename, ",", "T", "F") },
             "expected to live -- load_from_file() -- Case 3" );
    
    # check the names to make sure they were set correctly
    is_deeply( $table->get_row_names(), ["0", "1", "2", "3", "4"],
              "load_from_file -- look at row names in case 3" );
    is_deeply( $table->get_col_names(), ["A", "B", "C", "D", "E"],
              "load_from_file -- look at col names in case 3" );
    
    #-------
    # Case 2
    #-------
    ($fh, $filename) = tempfile();
    _make_tbl_file_c2($fh);
     lives_ok( sub{ $table->load_from_file($filename, ",", "F", "T") },
             "expected to live -- load_from_file() -- Case 2" );
    
    # check the names to make sure they were set correctly
    is_deeply( $table->get_row_names(), ["M", "N", "O", "P", "Q"],
              "load_from_file -- look at row names in case 2" );
    is_deeply( $table->get_col_names(), ["0", "1", "2", "3", "4"],
              "load_from_file -- look at col names in case 2" );
    
    #-------
    # Case 1
    #-------
    ($fh, $filename) = tempfile();
    _make_tbl_file_c1($fh);
     lives_ok( sub{ $table->load_from_file($filename, ",", "F", "F") },
             "expected to live -- load_from_file() -- Case 1" );
    
    # check the names to make sure they were set correctly
    is_deeply( $table->get_row_names(), ["0", "1", "2", "3", "4"],
              "load_from_file -- look at row names in case 1" );
    is_deeply( $table->get_col_names(), ["0", "1", "2", "3", "4"],
              "load_from_file -- look at col names in case 1" );
    
    # ------
    # test new parameter format
    # ------
    ($fh, $filename) = tempfile();
    _make_tbl_file_c5($fh);
    lives_ok( sub{ $table->load_from_file({file => $filename, sep => ","}) },
             "expected to live -- load_from_file($filename) -- case 5 new params format" );
    # check the names to make sure they were set correctly
    is_deeply( $table->get_row_names(), ["M", "N", "O", "P", "Q"],
              "load_from_file -- look at row names case 5 new params" );
    is_deeply( $table->get_col_names(), ["A", "B", "C", "D", "E"],
              "load_from_file -- look at col names case 5 new params" );
    
    ($fh, $filename) = tempfile();
    _make_tbl_file_c4($fh);
    lives_ok( sub{ $table->load_from_file({file => $filename, sep => ","}) },
             "expected to live -- load_from_file($filename) -- case 4 new params format" );
    # check the names to make sure they were set correctly
    is_deeply( $table->get_row_names(), ["M", "N", "O", "P", "Q"],
              "load_from_file -- look at row names case 4 new params" );
    is_deeply( $table->get_col_names(), ["A", "B", "C", "D", "E"],
              "load_from_file -- look at col names case 4 new params" );
    
    ($fh, $filename) = tempfile();
    _make_tbl_file_c3($fh);
    lives_ok( sub{ $table->load_from_file({
                                           file => $filename, sep => ",",
                                           has_row_names => "F"}) },
             "expected to live -- load_from_file($filename) -- case 3 new params format" );
    # check the names to make sure they were set correctly
    is_deeply( $table->get_row_names(), ["0", "1", "2", "3", "4"],
              "load_from_file -- look at row names case 3 new params" );
    is_deeply( $table->get_col_names(), ["A", "B", "C", "D", "E"],
              "load_from_file -- look at col names case 3 new params" );
    
    ($fh, $filename) = tempfile();
    _make_tbl_file_c2($fh);
    lives_ok( sub{ $table->load_from_file({
                                           file => $filename, sep => ",",
                                           has_col_header => "F"}) },
             "expected to live -- load_from_file($filename) -- case 2 new params format" );
    # check the names to make sure they were set correctly
    is_deeply( $table->get_row_names(), ["M", "N", "O", "P", "Q"],
              "load_from_file -- look at row names case 2 new params" );
    is_deeply( $table->get_col_names(), ["0", "1", "2", "3", "4"],
              "load_from_file -- look at col names case 2 new params" );
    
    ($fh, $filename) = tempfile();
    _make_tbl_file_c1($fh);
    lives_ok( sub{ $table->load_from_file({
                                           file => $filename, sep => ",",
                                           has_col_header => "F",
                                           has_row_names => "F"}) },
             "expected to live -- load_from_file($filename) -- case 1 new params format" );
    # check the names to make sure they were set correctly
    is_deeply( $table->get_row_names(), ["0", "1", "2", "3", "4"],
              "load_from_file -- look at row names case 1 new params" );
    is_deeply( $table->get_col_names(), ["0", "1", "2", "3", "4"],
              "load_from_file -- look at col names case 1 new params" );

    #------
    # test comment characters
    #------
    ($fh, $filename) = tempfile();
    _make_tbl_file_c1_comm($fh);
    lives_ok( sub{ $table->load_from_file({
                                           file => $filename, sep => ",",
                                           has_col_header => "F",
                                           has_row_names => "F",
                                           comm_char => "#"}) },
             "expected to live -- load_from_file($filename) -- case 1 comment character" );
    # check the names to make sure they were set correctly
    is_deeply( $table->get_row_names(), ["0", "1", "2", "3", "4"],
              "load_from_file -- look at row names when there is a comment at beginning" );
    is_deeply( $table->get_col_names(), ["0", "1", "2", "3", "4"],
              "load_from_file -- look at col names when there is a comment at the beginning" );

    is( $table->get_row_count(), 5, "load_from_file -- check row count with comments" );

    #------
    # test skip_after feature
    #------
    ($fh, $filename) = tempfile();
    _make_tbl_file_c4($fh);
    lives_ok( sub{ $table->load_from_file({
                                           file => $filename, sep => ",",
                                           skip_after => 2}) },
             "expected to live -- load_from_file($filename) -- case 4 skip_after => 2" );
    
    # check the names to make sure they were set correctly
    is_deeply( $table->get_row_names(), ["M"],
              "load_from_file -- look at row names after skip_after => 2" );
    is_deeply( $table->get_col_names(), ["A", "B", "C", "D", "E"],
              "load_from_file -- look at col names after skip_after => 2" );

    is( $table->get_row_count(), 1, "load_from_file -- check row count when using skip_after => 2" );
    
    # check that the function dies when passing illegal skip_after args
    throws_ok( sub{ $table->load_from_file({
                                            file => $filename, sep => ",",
                                            skip_after => "a"
                                           }) },
              'MyX::Generic::Digit::MustBeDigit', "load_from_file(skip_after => a) - caught" );
    throws_ok( sub{ $table->load_from_file({
                                            file => $filename, sep => ",",
                                            skip_after => -1
                                           }) },
              'MyX::Generic::Digit::TooSmall', "load_from_file(skip_after => -1) - caught" );
    
    #------
    # test skip_before feature
    #------
    ($fh, $filename) = tempfile();
    _make_tbl_file_c4_sb($fh);
    lives_ok( sub{ $table->load_from_file({
                                           file => $filename, sep => ",",
                                           skip_before => 2}) },
             "expected to live -- load_from_file($filename) -- case 4 skip_before => 2" );
    
    # check the names to make sure they were set correctly
    is_deeply( $table->get_row_names(), ["M", "N", "O", "P", "Q"],
              "load_from_file -- look at row names after skip_before => 2" );
    is_deeply( $table->get_col_names(), ["A", "B", "C", "D", "E"],
              "load_from_file -- look at col names after skip_before => 2" );

    is( $table->get_row_count(), 5, "load_from_file -- check row count when using skip_before => 2" );
    
    # check that the function dies when passing illegal skip_before args
    throws_ok( sub{ $table->load_from_file({
                                            file => $filename, sep => ",",
                                            skip_before => "a"
                                           }) },
              'MyX::Generic::Digit::MustBeDigit', "load_from_file(skip_before => a) - caught" );
    throws_ok( sub{ $table->load_from_file({
                                            file => $filename, sep => ",",
                                            skip_before => -1
                                           }) },
              'MyX::Generic::Digit::TooSmall', "load_from_file(skip_before => -1) - caught" );
    
    #------
    # test when there is empty lines
    #------
    ($fh, $filename) = tempfile();
    _make_tbl_file_c4_empty_line($fh); 
    lives_ok( sub{ $table->load_from_file({file => $filename, sep => ","}) },
             "expected to live -- load_from_file($filename) -- case 4 with empty lines" );
    
    # check the names to make sure they were set correctly
    is_deeply( $table->get_row_names(), ["M", "N", "O", "P", "Q"],
              "load_from_file -- with empty lines" );
    is_deeply( $table->get_col_names(), ["A", "B", "C", "D", "E"],
              "load_from_file -- with empty lines" );

    is( $table->get_row_count(), 5, "load_from_file -- check row count when there are empty lines" );
    
    
    # reset to use the case 4 table
    ($fh, $filename) = tempfile();
    _make_tbl_file_c4($fh);
    $table->load_from_file($filename, ",");
}

# test load_from_href_href
{
    my $table2;
    lives_ok( sub{ $table2 = Table->new() },
             "Expected to live -- building new table2");
    throws_ok( sub{ $table2->load_from_href_href() },
              'MyX::Generic::Undef::Param', "load_from_href_href() - caught" );
    
    my $href = {"A" => {"a" => 1, "b" => 2}, "B" => {"a" => 3, "b" => 4}};
    my $row_names = ["A", "B"];
    my $col_names = ["a", "b"];
    lives_ok( sub{ $table2->load_from_href_href($href, $row_names, $col_names) },
             "expected to live -- load_from_href_href(href)");
    
    is_deeply( $table2->get_col_names(), ["a", "b"], "table2 get_col_names()");
    is_deeply( $table2->get_row_names(), ["A", "B"], "table2 get_row_names()");
    my $str = "a,b
A,1,2
B,3,4
";
    is( $table2->to_str(","), $str, "table2 to_str()" );
}

# test load_from_string
{
    my $table3;
    lives_ok( sub{ $table3 = Table->new() },
                "Expected to live -- building new table3");

    throws_ok( sub{ $table3->load_from_string() },
                'MyX::Generic::Undef::Param', "load_from_string() - caught" );
    my $str = "a\tb\nA\t1\t3\nB\t2\t4\n";
    my $args = {str => $str, sep => "\t"};
    lives_ok( sub{ $table3->load_from_string($args) },
                "expected to live -- load_from_string(args)");
    
    is_deeply( $table3->get_col_names(), ["a", "b"], "table3 get_col_names()");
    is_deeply( $table3->get_row_names(), ["A", "B"], "table3 get_row_names()");
    
    is( $table3->to_str("\t"), $str, "table3 to_str()" );
}

# test order_rows
{
    # remember the upper case are rows and lower case are columns
    my $href = {"A" => {"a" => 1, "b" => 4}, "B" => {"a" => 3, "b" => 2}};
    my $t1 = Table->new();
    $t1->load_from_href_href($href, ["A", "B"], ["a", "b"]);
    
    throws_ok( sub{ $t1->order_rows() },
              'MyX::Generic::Undef::Param', "order_rows()" );
    
    throws_ok( sub{ $t1->order_rows("blah") },
              'MyX::Generic::Ref::UnsupportedType', "order_rows(blah)" );
    
    my @new_order = ("A");
    throws_ok( sub{ $t1->order_rows(\@new_order) },
              'MyX::Table::Order::Row::NamesNotEquiv', "order_rows(A)" );
    
    @new_order = ("A", "C");
    throws_ok( sub{ $t1->order_rows(\@new_order) },
              'MyX::Table::Order::Row::NamesNotEquiv', "order_rows(A,C)" );
    
    @new_order = ("B", "A");
    lives_ok( sub{ $t1->order_rows(\@new_order) },
             "expected to live -- order_rows(B,A)" );
    
    is_deeply( $t1->get_row_names(), ["B", "A"],
              "get_row_names() after order_rows(B,A)" );
    
    # make sure the values are ordered
    is_deeply( $t1->get_col("a"), [3,1],
               "get_col(a) after order_rows(B,A)" );
}

# test order_cols
{
    # remember the upper case are rows and lower case are columns
    my $href = {"A" => {"a" => 1, "b" => 4}, "B" => {"a" => 3, "b" => 2}};
    my $t1 = Table->new();
    $t1->load_from_href_href($href, ["A", "B"], ["a", "b"]);
    
    throws_ok( sub{ $t1->order_cols() },
              'MyX::Generic::Undef::Param', "order_cols()" );
    
    throws_ok( sub{ $t1->order_cols("blah") },
              'MyX::Generic::Ref::UnsupportedType', "order_cols(blah)" );
    
    my @new_order = ("a");
    throws_ok( sub{ $t1->order_cols(\@new_order) },
              'MyX::Table::Order::Col::NamesNotEquiv', "order_cols(a)" );
    
    @new_order = ("a", "c");
    throws_ok( sub{ $t1->order_cols(\@new_order) },
              'MyX::Table::Order::Col::NamesNotEquiv', "order_cols(a,c)" );
    
    @new_order = ("b", "a");
    lives_ok( sub{ $t1->order_cols(\@new_order) },
             "expected to live -- order_cols(b,a)" );
    
    is_deeply( $t1->get_col_names(), ["b", "a"],
              "get_col_names() after order_cols(b,a)" );
    
    # make sure the values are ordered
    is_deeply( $t1->get_row("A"), [4,1],
               "get_row(A) after order_cols(b,a)" );
}

# test sort_by_col
{
    # NOTE: the order of these tests is important.  Some of the tests use the
    #       table that was opperated on in the previous test so it assumes the output
    #       as the table is after the previous test
    
    #   a   b
    # A 1   4
    # B 3   2
    
    # remember the upper case are rows and lower case are columns
    my $href = {"A" => {"a" => 1, "b" => 4}, "B" => {"a" => 3, "b" => 2}};
    my $t1 = Table->new();
    $t1->load_from_href_href($href, ["A", "B"], ["a", "b"]);
    #print $t1->to_str() . "\n";
    
    throws_ok( sub{ $t1->sort_by_col() },
              'MyX::Generic::Undef::Param', "sort_by_col()" );
    throws_ok( sub{ $t1->sort_by_col("blah") },
              'MyX::Table::Col::UndefName', "sort_by_col(blah)" );
    
    lives_ok( sub{ $t1->sort_by_col("a") },
             "expected to live -- sort_by_col(a)" );
    is_deeply( $t1->get_row_names(), ["A", "B"],
              "get_row_names() after sort_by_col(a)" );
    
    lives_ok( sub{ $t1->sort_by_col("b") },
             "expected to live -- sort_by_col(b)" );
    is_deeply( $t1->get_row_names(), ["B", "A"],
              "get_row_names() after sort_by_col(b)" );
    
    # see what happens when I try getting a column
    # remember the table was sorted by column b
    is_deeply( $t1->get_col("a"), [3,1],
              "get_col(a) after sort_by_col(a)" );
    is_deeply( $t1->get_col("b"), [2,4],
              "get_col(a) after sort_by_col(a)" );
    is( $t1->get_value_at("A", "a"), 1,
       "get_value_at(A,a) after sort_by_col(b)" );
    
    # see what happens when I try getting a row
    
    my $numeric = 1;
    my $decreasing = 1;
    lives_ok( sub{ $t1->sort_by_col("b", $numeric, $decreasing) },
             "expected to live -- sort_by_col(b)" );
    is_deeply( $t1->get_row_names(), ["A", "B"],
              "get_row_names() after sort_by_col(b, numeric decreasing)" );
    
    
    # create an alphabetic table to test ordering
    $href = {"A" => {"a" => "a", "b" => "d"}, "B" => {"a" => "c", "b" => "b"}};
    $t1 = Table->new();
    $t1->load_from_href_href($href, ["A", "B"], ["a", "b"]);
    
    $numeric = 0;
    $decreasing = 0;
    lives_ok( sub{ $t1->sort_by_col("a", $numeric, $decreasing) },
             "expected to live -- sort_by_col(a)" );
    is_deeply( $t1->get_row_names(), ["A", "B"],
              "get_row_names() after sort_by_col(a, ascii increasing)" );
    
    $decreasing = 1;
    lives_ok( sub{ $t1->sort_by_col("b", $numeric, $decreasing) },
             "expected to live -- sort_by_col(b)" );
    is_deeply( $t1->get_row_names(), ["A", "B"],
              "get_row_names() after sort_by_col(b, ascii decreasing)" );
    
}

# test _check_row_name
{
    throws_ok( sub{ $table->_check_row_name() },
              'MyX::Generic::Undef::Param', "_check_row_name()" );
    throws_ok( sub{ $table->_check_row_name("Z") },
              'MyX::Table::Row::UndefName', "_check_row_name(Z)" );
    is( $table->_check_row_name("M"), 1, "_check_row_name(M)" );
}

# test _check_col_name
{
    throws_ok( sub{ $table->_check_col_name() },
              'MyX::Generic::Undef::Param', "_check_col_name()" );
    throws_ok( sub{ $table->_check_col_name("Z") },
              'MyX::Table::Col::UndefName', "_check_col_name(Z)" );
    is( $table->_check_col_name("A"), 1, "_check_col_name(M)" );
}

# test change_row_name
{
    throws_ok( sub{ $table->change_row_name() },
             'MyX::Generic::Undef::Param', "change_row_name()" );
    throws_ok( sub{ $table->change_row_name("M") },
             'MyX::Generic::Undef::Param', "change_row_name(M)" );
    throws_ok( sub{ $table->change_row_name("L", "P") },
             'MyX::Table::Col::UndefName', "chane_row_name(L,P)" );
    lives_ok( sub{ $table->change_row_name("M", "L") },
             "expected to live -- change_row_name(M,L)" );
    is_deeply( $table->get_row_names(), ["L", "N", "O", "P", "Q"],
              "get_row_names() after change_row_name(M,L)" );
    
    # reset the name to be A again
    lives_ok( sub{ $table->change_row_name("L", "M") },
             "expected to live -- change_row_name(L,M)" );
}

# test change_col_name
{
    throws_ok( sub{ $table->change_col_name() },
             'MyX::Generic::Undef::Param', "change_col_name()" );
    throws_ok( sub{ $table->change_col_name("A") },
             'MyX::Generic::Undef::Param', "change_col_name(A)" );
    throws_ok( sub{ $table->change_col_name("L", "P") },
             'MyX::Table::Col::UndefName', "chane_col_name(L,P)" );
    lives_ok( sub{ $table->change_col_name("A", "L") },
             "expected to live -- change_col_name(A,L)" );
    is_deeply( $table->get_col_names(), ["L", "B", "C", "D", "E"],
              "get_col_names() after change_col_name(A,L)" );
    
    # reset the name to be A again
    lives_ok( sub{ $table->change_col_name("L", "A") },
             "expected to live -- change_col_name(L,A)" );
}

# test get_row_index
{
    # remember the table was populated using the data in _make_tbl_file
    is( $table->get_row_index("M"), 0, "get_row_index(M)" );
    is( $table->get_row_index("Q"), 4, "get_row_index(Q)" );
}

# test get_col_index
{
    # remember the table was populated using the data in _make_tbl_file
    is( $table->get_col_index("A"), 0, "get_col_index(A)" );
    is( $table->get_col_index("E"), 4, "get_col_index(E)" );
}

# test get_value_at
{
    is( $table->get_value_at("M", "A"), 0, "get_value_at(M,A)" );
    is( $table->get_value_at("Q", "A"), 5, "get_value_at(M,A)" );
    is( $table->get_value_at("O", "D"), 4, "get_value_at(M,A)" );
}

# test get_value_at_fast
{
    is( $table->get_value_at_fast(0,0), 0, "get_value_at_fast(0,0)" );
    is( $table->get_value_at_fast(0,1), 3, "get_value_at_fast(0,1)" );
    is( $table->get_value_at_fast(1,0), 2, "get_value_at_fast(1,0)" );
    is( $table->get_value_at_fast(1,1), 0, "get_value_at_fast(1,1)" );
}

# test set_value_at
{
	lives_ok( sub{ $table->set_value_at("M", "A", 10) },
				"expected to live -- set_value_at(M, A, 10)" );
	is( $table->get_value_at("M", "A"), 10, "get_value_at(M,A) now 10" );
	
	# reset what I just change via set_value_at
	lives_ok( sub{ $table->set_value_at("M", "A", 0) },
				"expected to live -- set_value_at(M, A, 0) - change back" );
}

# test get_row
{
    is_deeply( $table->get_row("M"), [0,3,3,5,5], "get_row(M)" );
}

# test get_col
{
    is_deeply( $table->get_col("A"), [0,2,3,5,5], "get_col(A)" );
}

# test to_str
{
    my $str = "A,B,C,D,E
M,0,3,3,5,5
N,2,0,3,5,5
O,3,3,0,4,4
P,5,5,4,0,2
Q,5,5,4,2,0
";

    is( $table->to_str(","), $str, "to_str(,)" );
    is( $table->to_str({sep => ","}), $str, "to_str({sep=>\",\"})" );
    
    # test when I don't want to print the headers
    my $str2 = "M,0,3,3,5,5
N,2,0,3,5,5
O,3,3,0,4,4
P,5,5,4,0,2
Q,5,5,4,2,0
";
    
    is( $table->to_str(",", "F"), $str2, "to_str(, F)" );
    is( $table->to_str({sep => ",", print_col_header => "F"}),
       $str2, "to_str({sep=>\",\", print_col_header => F})" );
    
    # test when I don't want to print the col headers or row names
    my $str3 = "0,3,3,5,5
2,0,3,5,5
3,3,0,4,4
5,5,4,0,2
5,5,4,2,0
";
    
    is( $table->to_str(",", "F"), $str2, "to_str(, F)" );
    is( $table->to_str({sep => ",", print_col_header => "F", print_row_names => "F"}),
       $str3, "to_str({sep=>\",\", print_col_header => F, print_row_names => F})" );
}

# test rekey_row_names
{
    # create some test tables
    my $t = Table->new();
    my $href = {A => {a=>1, b=>4, c=>3}, B => {a=>3, b=>2, c=>3}};
    $t->load_from_href_href($href, ["A", "B"], ["a", "b", "c"]);
    
    #   a   b   c
    # A 1   4   3
    # B 3   2   3
    
    throws_ok( sub{ $t->rekey_row_names() },
              "MyX::Generic::Undef::Param", "caught - rekey_row_names() ");
    throws_ok( sub{ $t->rekey_row_names("blah") },
               "MyX::Table::Col::UndefName",
               "caught - rekey_col_headers(blah)" );
    throws_ok( sub{ $t->rekey_row_names("c") },
              "MyX::Table::NamesNotUniq", "caught - rekey_row_names(c) ");
    
    lives_ok( sub{ $t->rekey_row_names("a")},
              "expected to live - rekey_row_names(a)" );
    is_deeply( $t->get_row_names(), [1,3],
               "get_row_names after rekey_row_names(a)" );
    is( $t->get_row_names_header(), "a", "check row names header - a" );
    is_deeply( $t->get_col_names(), ["b","c", "old_row_names"],
               "check new col names" );
    is_deeply( $t->get_col("old_row_names"), ["A", "B"],
               "get old row names" );
    
    # reset table and test when there is a row_names_header
    $t->reset();
    $t->load_from_href_href($href, ["A", "B"], ["a", "b", "c"]);
    $t->_set_row_names_header("header");
    lives_ok( sub{ $t->rekey_row_names("a")},
              "expected to live - rekey_row_names(a)" );
    is( $t->get_row_names_header(), "a", "check row names header - a" );
    is_deeply( $t->get_col_names(), ["b","c", "header"],
               "check new col names" );
    
    # reset table and test when the new row names header is given in rekey
    $t->reset();
    $t->load_from_href_href($href, ["A", "B"], ["a", "b", "c"]);
    $t->_set_row_names_header("header");
    lives_ok( sub{ $t->rekey_row_names("a", "header2")},
              "expected to live - rekey_row_names(a)" );
    is( $t->get_row_names_header(), "a", "check row names header - a" );
    is_deeply( $t->get_col_names(), ["b","c", "header2"],
               "check new col names" );
    
    
    # test rekey on a table sorted by column
    $t->reset();
    $t->load_from_href_href($href, ["A", "B"], ["a", "b", "c"]);
    #   a   b   c
    # B 3   2   3
    # A 1   4   3
    $t->sort_by_col("b");
    lives_ok( sub{ $t->rekey_row_names("a") },
              "expected to live - rekey_row_names(a)" );
    is_deeply( $t->get_row_names(), [3,1],
               "get_row_names after rekey_row_names(a) - [3,1]" );
    is_deeply( $t->get_col("old_row_names"), ["B", "A"],
               "get old row names" );
    
    # now test another sort and rekey
    $t->sort_by_col("old_row_names");
    lives_ok( sub{ $t->rekey_row_names("old_row_names") },
              "expected to live - rekey_row_names(old_row_names) " );
    is_deeply( $t->get_row_names(), ["A","B"],
               "get_row_names after rekey_row_names(old_row_names) - [A,B]" );
    is_deeply( $t->get_col("a"), [1, 3],
               "get_col(a) - a col goes back to table" );
    is( $t->get_row_names_header(), "", "get_row_names_header() - empty")
        
    # NOTE: after running the rekey the table will no longer be sorted!
    # NOTE: this this key function will not work on numeric table unless row names are numeric
}

# test rekey_col_headers
{
    # create some test tables
    my $t = Table->new();
    my $href = {A => {a=>1, b=>1, c=>1}, B => {a=>3, b=>2, c=>4}};
    $t->load_from_href_href($href, ["A", "B"], ["a", "b", "c"]);
    
    #   a   b   c
    # A 1   1   1
    # B 3   2   4
    
    throws_ok( sub{ $t->rekey_col_headers() },
              "MyX::Generic::Undef::Param", "caught - rekey_col_headers() ");
    throws_ok( sub{ $t->rekey_col_headers("A") },
              "MyX::Generic::Undef::Param", "caught - rekey_col_headers(A,) ");
    throws_ok( sub{ $t->rekey_col_headers("blah", "blah") },
               "MyX::Table::Row::UndefName",
               "caught - rekey_col_headers(blah, blah)" );
    throws_ok( sub{ $t->rekey_col_headers("A", "old_col_headers") },
              "MyX::Table::NamesNotUniq", "caught - rekey_col_headers(A) ");
    
    lives_ok( sub{ $t->rekey_col_headers("B", "old_col_headers")},
              "expected to live - rekey_col_headers(B, old_col_headers)" );
    is_deeply( $t->get_col_headers(), [3,2,4],
               "get_row_names after rekey_col_headers(B, old_col_headers)" );
    is_deeply( $t->get_row("old_col_headers"), ["a", "b", "c"],
               "get old col headers" );
    
    # there is currently no sort by row functionality here so I don't test to
    # see how that might impact re-keying
    
    # NOTE: after running the rekey the table will no longer be sorted!
    # NOTE: this this key function will not work on numeric table unless row names are numeric
}

# test save
{
    # these tests could be more robust.  right now it simply tests
    # that a file was created and non-empty
    throws_ok( sub{ $table->save() },
              'MyX::Generic::Undef::Param', "save()" );
    
    my ($fh, $filename) = tempfile();
    close($fh);
    lives_ok( sub{ $table->save($filename) },
             "expected to live -- save($filename)" );
    
    cmp_ok( -s $filename, ">", 0, "saved file is not empty" );
    
    # test the new parameter format
    # also implicetly tests the default value for sep
    ($fh, $filename) = tempfile();
    close($fh);
    lives_ok( sub{ $table->save({file => $filename,
                                 print_col_header => "T",
                                 print_row_names => "T"}) },
             "expected to live -- save( new parmaeters sytle) - $filename" );
    
    cmp_ok( -s $filename, ">", 0, "saved file is not empty using new parameter style" );
}

# test add_row
{
    throws_ok( sub{ $table->add_row() },
              'MyX::Generic::Undef::Param', "caught - add_row()" );
    throws_ok( sub{ $table->add_row("Z") },
              'MyX::Generic::Undef::Param', "caught - add_row(Z)" );
    throws_ok( sub{ $table->add_row("M", [1,2,3,4,5]) },
              'MyX::Table::Row::NameInTable', "caught - add_row(M)" );
    throws_ok( sub{ $table->add_row("Z", {"A"=>1}) },
              'MyX::Generic::Ref::UnsupportedType', "caught - add_row(Z, {A=>1})" );
    throws_ok( sub{ $table->add_row("Z", [1,2,3]) },
              'MyX::Table::BadDim', "caught - add_row(Z, [1,2,3])" );
        
    lives_ok( sub{ $table->add_row("Z", [1,2,3,4,5]) },
             "expected to live -- add_row(Z, [1,2,3,4,5])" );
    is( $table->get_row_count(), 6, "get_row_count() after add_row(Z)" );
    my $str = "A,B,C,D,E
M,0,3,3,5,5
N,2,0,3,5,5
O,3,3,0,4,4
P,5,5,4,0,2
Q,5,5,4,2,0
Z,1,2,3,4,5
";
    is( $table->to_str(","), $str, "to_str() after add_row(Z)" );
    
    
    # now make sure everything works when I pass in an aref of names
    throws_ok( sub{ $table->add_row("Y", [1,2,3,4,5], ["A"]) },
              'MyX::Table::BadDim',
              "caught - add_row(Y, [1,2,3,4,5], [A])" );
    throws_ok( sub{ $table->add_row("Y", [1,2,3,4,5], {"A"=> 1}) },
              'MyX::Generic::Ref::UnsupportedType',
              "caught - add_row(Y, [1,2,3,4,5], {A=>1})" );
    throws_ok( sub{ $table->add_row("Y", [1,2,3,4,5], ["A", "B", "C", "D", "X"]) },
              'MyX::Table::Col::UndefName',
              "caught - add_row(Y, [1,2,3,4,5], [A, B, C, D, X])" );
    lives_ok( sub{ $table->add_row("Y", [1,2,3,4,5], ["E", "B", "C", "D", "A"]) },
             "expected to live -- add_row(Y, [1,2,3,4,5], [E, B, C, D, A])" );
    is( $table->get_row_count(), 7, "get_row_count() after add_row(Y)" );
    $str = "A,B,C,D,E
M,0,3,3,5,5
N,2,0,3,5,5
O,3,3,0,4,4
P,5,5,4,0,2
Q,5,5,4,2,0
Z,1,2,3,4,5
Y,5,2,3,4,1
";
    is( $table->to_str(","), $str, "to_str() after add_row(Y)" );
    
    # reset the table to be what is in the _make_tbl_file
    my($fh, $filename) = tempfile();
    _make_tbl_file_c4($fh);
    lives_ok( sub{ $table->load_from_file($filename, ",") },
             "expected to live -- reset the table" );
    
    # test when a row is added to an empty table
    my $new_tbl = Table->new();
    throws_ok( sub{ $new_tbl->add_row("A", [1,2]) },
              'MyX::Generic::Undef::Param',
              "caught - add_row() -- first row w/ no names" );
    lives_ok( sub{ $new_tbl->add_row("A", [1,2], ["a","b"]) },
             "expected to live -- add_row(A, [1,2], [a,b]) -- first row");
    is( $new_tbl->get_col_count(), 2, "new_tbl get_col_count()" );
    is( $new_tbl->get_row_count(), 1, "new_tbl get_row_count()" );
    is_deeply( $new_tbl->get_row_names(), ["A"], "new_tbl get_row_names()" );
    is_deeply( $new_tbl->get_col_names(), ["a", "b"], "new_tbl get_col_names()" );
}

# test add_col
{
    throws_ok( sub{ $table->add_col() },
              'MyX::Generic::Undef::Param', "caught - add_col()" );
    throws_ok( sub{ $table->add_col("Z") },
              'MyX::Generic::Undef::Param', "caught - add_col(Z)" );
    throws_ok( sub{ $table->add_col("A", [1,2,3,4,5]) },
              'MyX::Table::Col::NameInTable', "caught - add_col(A)" );
    throws_ok( sub{ $table->add_col("Z", {"A"=>1}) },
              'MyX::Generic::Ref::UnsupportedType', "caught - add_col(Z, {A=>1})" );
    throws_ok( sub{ $table->add_col("Z", [1,2,3]) },
              'MyX::Table::BadDim', "caught - add_col(Z, [1,2,3])" );
        
    lives_ok( sub{ $table->add_col("Z", [1,2,3,4,5]) },
             "expected to live -- add_col(Z, [1,2,3,4,5])" );
    is( $table->get_col_count(), 6, "get_col_count() after add_col(Z)" );
    my $str = "A,B,C,D,E,Z
M,0,3,3,5,5,1
N,2,0,3,5,5,2
O,3,3,0,4,4,3
P,5,5,4,0,2,4
Q,5,5,4,2,0,5
";
    is( $table->to_str(","), $str, "to_str() after add_col(Z)" );
    
    
    # now make sure everything works when I pass in an aref of names
    throws_ok( sub{ $table->add_col("Y", [1,2,3,4,5], ["M"]) },
              'MyX::Table::BadDim',
              "caught - add_col(Y, [1,2,3,4,5], [M])" );
    throws_ok( sub{ $table->add_col("Y", [1,2,3,4,5], {"M"=> 1}) },
              'MyX::Generic::Ref::UnsupportedType',
              "caught - add_col(Y, [1,2,3,4,5], {M=>1})" );
    throws_ok( sub{ $table->add_col("Y", [1,2,3,4,5], ["M", "N", "O", "P", "X"]) },
              'MyX::Table::Row::UndefName',
              "caught - add_col(Y, [1,2,3,4,5], [M, N, O, P, X])" );
    lives_ok( sub{ $table->add_col("Y", [1,2,3,4,5], ["Q", "N", "O", "P", "M"]) },
             "expected to live -- add_col(Y, [1,2,3,4,5], [Q, N, O, P, M])" );
    is( $table->get_col_count(), 7, "get_col_count() after add_col(Y)" );
    $str = "A,B,C,D,E,Z,Y
M,0,3,3,5,5,1,5
N,2,0,3,5,5,2,2
O,3,3,0,4,4,3,3
P,5,5,4,0,2,4,4
Q,5,5,4,2,0,5,1
";
    is( $table->to_str(","), $str, "to_str() after add_col(Y)" );
    
    # reset the table to be what is in the _make_tbl_file
    my($fh, $filename) = tempfile();
    _make_tbl_file_c4($fh);
    lives_ok( sub{ $table->load_from_file($filename, ",") },
             "expected to live -- reset the table" );
}

# test _check_subset_params
{
    # create some test tables
    my $t = Table->new();
    my $href = {A => {a=>1, b=>2, c=>3}, B => {a=>3, b=>4, c=>5}};
    $t->load_from_href_href($href, ["A", "B"], ["a", "b", "c"]);
    
    my $in_params;  # this gets set and reset multiple times below
    
    # the case with no parameters will naturally do nothing to the table
    my $obs_params;
    lives_ok( sub{ $obs_params = $t->_check_subset_params() },
             "expected to live -- _check_subset_params()" );
    # In the following test I want to see if all the rows/cols are present in
    # the starting table and subseted table
    is_deeply([sort keys %{$obs_params->{rows}}], [sort @{$t->get_row_names()}],
              "_check_subset_params() -- all rows" );
    is_deeply([sort keys %{$obs_params->{cols}}], [sort @{$t->get_col_names()}],
              "_check_subset_params() -- all cols" );
    is($obs_params->{drop}, 0, "_check_subset_params() -- drop" );
    
    # checks that errors are thrown when I provide the wrong type of parameters
    $in_params->{rows} = "scalar string";
    throws_ok( sub{ $t->_check_subset_params($in_params) },
              'MyX::Generic::Ref::UnsupportedType', "caught - _check_subset_params(row scalar)" );
    
    undef %{$in_params};
    $in_params->{cols} = "scalar string";
    throws_ok( sub{ $t->_check_subset_params($in_params) },
              'MyX::Generic::Ref::UnsupportedType', "caught - _check_subset_params(col scalar)" );
    
    # checks when arrays are passed instead of hashes
    undef %{$in_params};
    $in_params->{rows} = ["A", "B"];
    lives_ok( sub{ $obs_params = $t->_check_subset_params($in_params) },
                "expected to live -- _check_subset_params(with aref)" );
    is( ref($obs_params->{rows}), "HASH", "rows should be a hash" );
    
    undef %{$in_params};
    $in_params->{cols} = ["A", "B"];
    lives_ok( sub{ $obs_params = $t->_check_subset_params($in_params) },
                "expected to live -- _check_subset_params(with aref)" );
    is( ref($obs_params->{cols}), "HASH", "cols should be a hash" );
    
    # test the drop parameter
    undef %{$in_params};
    $in_params->{drop} = "abc";  # wrong type -- not a boolean
    throws_ok( sub{ $t->_check_subset_params($in_params) },
              'MyX::Generic::BadValue', "caught - _check_subset_params(drop scalar)" );

    $in_params->{drop} = "T";
    lives_ok( sub{ $obs_params = $t->_check_subset_params($in_params) },
                "expected to live -- _check_subset_params(drop)" );
    is( $obs_params->{drop}, 1, "drop should be 1 ie true" );
    is_deeply( href_to_aref($obs_params->{rows}), [],
              "_check_subset_params(drop) -- keep all rows" );
    is_deeply( href_to_aref($obs_params->{cols}), [],
              "_check_subset_params(drop) -- keep all cols" );
    
    # test what happens when I mistakenly use row or col as the parameter
    lives_ok( sub{ $obs_params = $t->_check_subset_params({col=>["A"]}) },
                "expected to live -- _check_subset_params(col) - instead of cols" );
    is_deeply( href_to_aref($obs_params->{cols}), ["A"],
              "_check_subset_params(col) -- values after col" );
    lives_ok( sub{ $obs_params = $t->_check_subset_params({row=>["a"]}) },
                "expected to live -- _check_subset_params(row) - instead of rows" );
    is_deeply( href_to_aref($obs_params->{rows}), ["a"],
              "_check_subset_params(row) -- values after row" );
}

# test subset
{
    # create some test tables
    my $t = Table->new();
    my $href = {A => {a=>1, b=>2, c=>3}, B => {a=>3, b=>4, c=>5}};
    $t->load_from_href_href($href, ["A", "B"], ["a", "b", "c"]);
    
    # subset a row
    lives_ok( sub{ $t->subset( {rows => ["A"]} ) },
                "expected to live -- subset(row - A)" );
    is_deeply( $t->get_row_names(), ["A"], "subset(rows - A)" );
    
    # reset the table and test the drop functionality for rows
    $t->load_from_href_href($href, ["A", "B"], ["a", "b", "c"]);
    lives_ok( sub{ $t->subset( {rows => ["A"], drop => "T"} ) },
                "expected to live -- subset(row - A, drop)" );
    is( $t->get_row_count(), 1, "subset(rows - A, drop) - row count" );
    is_deeply( $t->get_row_names(), ["B"], "subset(rows - A, drop)" );
    
    # reset the table and subset a column
    $t->load_from_href_href($href, ["A", "B"], ["a", "b", "c"]);
    lives_ok( sub{ $t->subset( {cols => ["a"]} ) },
                "expected to live -- subset(col - a)" );
    is_deeply( $t->get_col_names(), ["a"], "subset(cols - a)" );
    is_deeply( $t->get_row_names(), ["A", "B"], "subset(cols - a) check rows" );
    
    # reset the table and test the drop functionality for cols
    $t->load_from_href_href($href, ["A", "B"], ["a", "b", "c"]);
    lives_ok( sub{ $t->subset( {cols => ["a"], drop => "T"} ) },
                "expected to live -- subset(col - a, drop)" );
    is( $t->get_col_count(), 2, "subset(col - a, drop) - col count" );
    is_deeply( $t->get_col_names(), ["b","c"], "subset(col - a, drop)" );
    
    # reset the table and test the drop functionality for rows and cols
    $t->load_from_href_href($href, ["A", "B"], ["a", "b", "c"]);
    my $exp_href = {B => {b=>4}};
    my $exp_t = Table->new();
    $exp_t->load_from_href_href($exp_href, ["B"], ["b"]);
    lives_ok( sub{ $t->subset( {rows => ["B"], cols => ["b"]} ) },
                "expected to live -- subset([B], [b])" );
    is( $t->get_row_count(), 1, "subset([B], [b]) - row count" );
    is( $t->get_col_count(), 1, "subset([B], [b]) - col count" );
    is_deeply( $t->get_col_names(), $exp_t->get_col_names(),
              "subset([B], [b]) - check table col names" );
    is_deeply( $t->get_row_names(), $exp_t->get_row_names(),
              "subset([B], [b]) - check table row names" );
    is( $t->get_value_at("B", "b"), $exp_t->get_value_at("B", "b"),
       "subset([B], [b]) - check values");
    
    # reset the table and test the drop functionality for rows and cols when
    # drop is set to true    
    $t->load_from_href_href($href, ["A", "B"], ["a", "b", "c"]);
    $exp_href = {B => {b=>4}};
    $exp_t->load_from_href_href($exp_href, ["B"], ["b"]);
    lives_ok( sub{ $t->subset( {rows => ["A"], cols => ["a", "c"], drop => "T"} ) },
                "expected to live -- subset([A], [a,c], T)" );
    is( $t->get_row_count(), 1, "subset([A], [a,c], T) - row count" );
    is( $t->get_col_count(), 1, "subset([A], [a,c], T) - col count" );
    is_deeply( $t->get_col_names(), $exp_t->get_col_names(),
              "subset([A], [a,c], T) - check table col names" );
    is_deeply( $t->get_row_names(), $exp_t->get_row_names(),
              "subset([A], [a,c], T) - check table row names" );
    is( $t->get_value_at("B", "b"), $exp_t->get_value_at("B", "b"),
       "subset([A], [a,c], T) - check values");
    
    # what happens when I try subsetting with a row that is not in the table
    # the table gets emptied!
    $t->load_from_href_href($href, ["A", "B"], ["a", "b", "c"]);
    lives_ok( sub{ $t->subset( {rows => ["X"]} ) },
                "expected to live -- subset([X])" );
    is( $t->get_row_count(), 0, "subset([X]) - row count" );
    is( $t->get_col_count(), 0, "subset([X]) - col count" );
    
    # what happens when I try subsetting with a col that is not in the table
    # the table gets emptied!
    $t->load_from_href_href($href, ["A", "B"], ["a", "b", "c"]);
    lives_ok( sub{ $t->subset( {cols => ["y"]} ) },
                "expected to live -- subset([y])" );
    is( $t->get_row_count(), 0, "subset([y]) - row count" );
    is( $t->get_col_count(), 0, "subset([y]) - col count" );
}

# test _check_merge_params
{
    # create a test table
    my $t1 = Table->new();
    my $href = {A => {a=>1, b=>2}, B => {a=>3, b=>4}};
    $t1->load_from_href_href($href, ["A", "B"], ["a", "b"]);
    
    my $in_params = {y_tbl => $t1};
    my $out_params;
    lives_ok( sub{ $out_params = Table::_check_merge_params($in_params) },
             "expected to live -- _check_merge_params(t1) ");
    is( $out_params->{y_tbl}, $t1, "_check_merge_params() -- y_tbl");
    is( $out_params->{all_x}, 0, "_check_merge_params() -- all_x");
    is( $out_params->{all_y}, 0, "_check_merge_params() -- all_y");
    
    $in_params->{all_x} = "T";
    lives_ok( sub{ $out_params = Table::_check_merge_params($in_params) },
             "expected to live -- _check_merge_params(t1, all_x=T) ");
    is( $out_params->{all_x}, 1, "_check_merge_params() -- all_x=T");
    
    $in_params->{all_y} = "T";
    lives_ok( sub{ $out_params = Table::_check_merge_params($in_params) },
             "expected to live -- _check_merge_params(t1, all_y=T) ");
    is( $out_params->{all_y}, 1, "_check_merge_params() -- all_y=T");
}

# test merge
{
    # create some test tables
    my $t1 = Table->new();
    my $href = {A => {a=>1, b=>2}, B => {a=>3, b=>4}};
    $t1->load_from_href_href($href, ["A", "B"], ["a", "b"]);

    my $t2 = Table->new();
    $t2->add_row("A", [5,6], ["x", "y"]);
    $t2->add_row("B", [7,8], ["x", "y"]);
    #my $href2 = {A => {x=>5, y=>6}, B => {x=>7, y=>8}};
    #$t2->load_from_href_href($href2, ["A", "B"], ["x", "y"]);
    
    ###
    # test when no parameter is given
    ###
    throws_ok( sub{ $t1->merge() },
              'MyX::Generic::Undef::Param', "caught - merge()" );
    
    ###
    # test for a correct merging
    ###
    my $merged;
    my $params_href = {y_tbl => $t2};
    lives_ok( sub{ $merged = $t1->merge($params_href) },
             "expected to live -- t1->merge(t2)" );
    is( $merged->get_col_count(), 4, "get_col_count() after merge(t2)" );
    is( $merged->get_row_count(), 2, "get_row_count() after merge(t2)" );
    my $str = "a,b,x,y
A,1,2,5,6
B,3,4,7,8
";
    is( $merged->to_str(","), $str, "to_str after merge(t2)" );
    
    ###
    # make sure it works when all_y and all_x are set to TRUE
    ###
    $params_href->{all_x} = "T";
    $params_href->{all_y} = "T";
    lives_ok( sub{ $merged = $t1->merge($params_href) },
             "expected to live -- t1->merge(t2)" );
    is( $merged->to_str(","), $str, "to_str after merge(t2)" );
    
    ###
    # try one that has a duplicate column name
    ###
    $t2->change_col_name("x", "a");
    lives_ok( sub{ $params_href->{y_tbl} },
             "expected to live --change_col_name()" );
    lives_ok( sub{ $merged = $t1->merge($params_href) },
             "expected to live (dup col name) -- t1->merge(t2)" );
    $str = "a,b,a_y,y
A,1,2,5,6
B,3,4,7,8
";
    is( $merged->to_str(","), $str, "to_str after merge(t2) (dup col name)" );
    
    lives_ok( sub{ $t2->change_col_name("a", "x") },
             "expected to live -- change col back to a");
    
    ###
    # try when X has extra rows
    ###
    lives_ok( sub{ $t1->add_row("C", [10,11]) },
             "expected to live --adding row to t1");
    lives_ok( sub{ $merged = $t1->merge($params_href) },
             "expected to live (extra X rows) -- t1->merge(t2)" );
    $str = "a,b,x,y
A,1,2,5,6
B,3,4,7,8
C,10,11,NA,NA
";
    is( $merged->to_str(","), $str, "to_str after merge(t2) (extra X rows)" );
    
    ###
    # try when Y has extra rows
    ###
    lives_ok( sub{ $t2->add_row("D", [12,13]) },
             "expected to live --adding row to t2");
    lives_ok( sub{ $merged = $t1->merge($params_href) },
             "expected to live (extra Y rows) -- t1->merge(t2)" );
    $str = "a,b,x,y
A,1,2,5,6
B,3,4,7,8
C,10,11,NA,NA
D,NA,NA,12,13
";
    is( $merged->to_str(","), $str, "to_str after merge(t2) (extra Y rows)" );
}

# test cbind
{
    # create two table to cbind -- remember big letters are rows
    my $t1 = Table->new();
    my $href = {A => {a=>1, b=>2}, B => {a=>3, b=>4}};
    $t1->load_from_href_href($href, ["A", "B"], ["a", "b"]);
    
    my $t2 = Table->new();
    $href = {A => {c=>1, d=>2}, B => {c=>3, d=>4}};
    $t2->load_from_href_href($href, ["A", "B"], ["c", "d"]);
    
    # this is the expected table
    my $exp_tbl = Table->new();
    $href = {A => {a=>1, b=>2, c=>1, d=>2}, B => {a=>3, b=>4, c=>3, d=>4}};
    $exp_tbl->load_from_href_href($href, ["A", "B"], ["a", "b", "c", "d"]);
    
    my $bad_tbl1 = Table->new(); # incorrect number of rows
    $href = {A => {c=>1, d=>2}};
    $bad_tbl1->load_from_href_href($href, ["A"], ["c", "d"]);
    
    my $bad_tbl2 = Table->new(); # non-matching row names
    $href = {A => {c=>1, d=>2}, C => {c=>3, d=>4}};
    $bad_tbl2->load_from_href_href($href, ["A", "C"], ["c", "d"]);
    
    # check for errors when the tbl2 parameter is missing
    throws_ok( sub{ $t1->cbind() },
              'MyX::Generic::Undef::Param', "caught - cbind()" );
    
    # check for errors when the tbl2 parameter is not the correct type
    throws_ok( sub{ $t1->cbind("blah") },
              'MyX::Generic::Ref::UnsupportedType', "caught - cbind(blah)" );
    
    # check for errors when the row counts do not match
    throws_ok( sub{ $t1->cbind($bad_tbl1) },
              'MyX::Table::Bind::NamesNotEquiv',
              "caught - cbind(bad_tbl1) - row counts do not match" );
    
    # check for errors when the row names do not match
    throws_ok( sub{ $t1->cbind($bad_tbl2) },
              'MyX::Table::Bind::NamesNotEquiv',
              "caught - cbind(bad_tbl2) - col names do not match" );
    
    # check for the correct output
    lives_ok( sub{ $t1->cbind($t2) },
             "expected to live -- t1->cbind(t2) ");
    is( $t1->to_str(","), $exp_tbl->to_str(","),
       "to_str after t1->cbind(t2)" );
}

# test rbind
{
    # create two table to rbind -- remember big letters are rows
    my $t1 = Table->new();
    my $href = {A => {a=>1, b=>2}, B => {a=>3, b=>4}};
    $t1->load_from_href_href($href, ["A", "B"], ["a", "b"]);
    
    my $t2 = Table->new();
    $href = {C => {a=>1, b=>2}, D => {a=>3, b=>4}};
    $t2->load_from_href_href($href, ["C", "D"], ["a", "b"]);
    
    # this is the expected table
    my $exp_tbl = Table->new();
    $href = {A => {a=>1, b=>2}, B => {a=>3, b=>4}, C => {a=>1, b=>2}, D => {a=>3, b=>4}};
    $exp_tbl->load_from_href_href($href, ["A", "B", "C", "D"], ["a", "b"]);
    
    my $bad_tbl1 = Table->new();
    $href = {C => {a=>1}, D => {a=>3,}};
    $bad_tbl1->load_from_href_href($href, ["C", "D"], ["a"]);
    
    my $bad_tbl2 = Table->new();
    $href = {C => {x=>1, b=>2}, D => {x=>3, b=>4}};
    $bad_tbl2->load_from_href_href($href, ["C", "D"], ["x", "b"]);
    
    # check for errors when the tbl2 parameter is missing
    throws_ok( sub{ $t1->rbind() },
              'MyX::Generic::Undef::Param', "caught - rbind()" );
    
    # check for errors when the tbl2 parameter is not the correct type
    throws_ok( sub{ $t1->rbind("blah") },
              'MyX::Generic::Ref::UnsupportedType', "caught - rbind(blah)" );
    
    # check for errors when the col counts do not match
    throws_ok( sub{ $t1->rbind($bad_tbl1) },
              'MyX::Table::Bind::NamesNotEquiv',
              "caught - rbind(bad_tbl1) - col counts do not match" );
    
    # check for errors when the col names do not match
    throws_ok( sub{ $t1->rbind($bad_tbl2) },
              'MyX::Table::Bind::NamesNotEquiv',
              "caught - rbind(bad_tbl2) - row names do not match" );
    
    # check for the correct output
    lives_ok( sub{ $t1->rbind($t2) },
             "expected to live -- t1->rbind(t2) ");
    is( $t1->to_str(","), $exp_tbl->to_str(","),
       "to_str after t1->rbind(t2)" );
}

# test copy
{
    # create some test tables
    my $t1 = Table->new();
    my $href = {A => {a=>1, b=>2}, B => {a=>3, b=>4}};
    $t1->load_from_href_href($href, ["A", "B"], ["a", "b"]);
    
    my $copy;
    lives_ok( sub{ $copy = $t1->copy() },
             "expected to live -- copy()" );
    
    #is_deeply($t1, $copy, "copy()" );
    is( $copy->get_row_count(), $t1->get_row_count(),
       "copy() -- get row count" );
    is( $copy->get_col_count(), $t1->get_col_count(),
       "copy() -- get col count" );
    is_deeply($copy->get_col_names(), $t1->get_col_names(),
              "copy() -- get col names");
    is_deeply($copy->get_row_names(), $t1->get_row_names(),
              "copy() -- get row names");
    is($copy->get_row_names_header(), $t1->get_row_names_header(),
       "copy() -- get row names header");
    is_deeply($copy->get_row("A"), $t1->get_row("A"),
              "copy() -- checking row A");
    is_deeply($copy->get_row("B"), $t1->get_row("B"),
              "copy() -- checking row B");
}

# test reset
{
    # create some test tables
    my $t1 = Table->new();
    my $href = {A => {a=>1, b=>2}, B => {a=>3, b=>4}};
    $t1->load_from_href_href($href, ["A", "B"], ["a", "b"]);
    
    lives_ok( sub{ $t1->reset() } ,
             "expected to live -- reset()" );
    
    # note that when there are no row or column names the get_row_names and
    # get_col_names functions return an empty array reference.
    my @empty = ();
    is_deeply( $t1->get_row_names(), \@empty, "reset() -- row names" );
    is_deeply( $t1->get_col_names(), \@empty, "reset() -- col names" );
    
    is_deeply( $t1->get_row_names(1), \@empty, "reset() -- row names by index order" );
    is_deeply( $t1->get_col_names(1), \@empty, "reset() -- col names by index order" );
    
    is( $t1->get_row_count(), 0, "reset() -- row count" );
    is( $t1->get_col_count(), 0, "reset() -- col count" );
    is( $t1->get_row_names_header(), undef, "reset() -- row names header" );
}

# test transpose
{
    # create some test tables
    my $t1 = Table->new();
    my $href = {A => {a=>1, b=>2, c=>3}, B => {a=>3, b=>4, c=>5}};
    $t1->load_from_href_href($href, ["A", "B"], ["a", "b", "c"]);
    
    foreach my $r ( @{$t1->get_row_names()} ) {
        #print "t/r: $r\n";
    }
    
    lives_ok( sub{ $t1->transpose() } ,
             "expected to live -- transpose()" );
    
    is( $t1->get_row_count(), 3, "transpose() -- get row count" );
    is( $t1->get_col_count(), 2, "transpose() -- get col count" );
    
    my @new_row_names = ("a", "b", "c");
    is_deeply( $t1->get_row_names(), \@new_row_names,
              "transpose -- row names" );
    
    my @new_col_names = ("A", "B");
    is_deeply( $t1->get_col_names(), \@new_col_names,
              "transpose -- col names" );
    
    # I'm only explicetly checking a few of the values in the table
    is( $t1->get_value_at("a", "A"), 1, "transpose() -- get_value_at(a,A)");
    is( $t1->get_value_at("a", "B"), 3, "transpose() -- get_value_at(a,A)");
    is( $t1->get_value_at("b", "A"), 2, "transpose() -- get_value_at(a,A)");
    is( $t1->get_value_at("b", "B"), 4, "transpose() -- get_value_at(a,A)");
}

# test _decrement_name_indicies
{
    my $href = {"A" => 0, "B" => 1, "C" => 2};
    my $i = 1;
    
    # The following test is as if I'm droping row (or col) "B".
    # Note that the _decrement_name_indicies function does not remove the name
    # itself.  So in the expected href (exp) B still remains and it's index is
    # still the same.  It is removed in the drop_row or drop_col function.
    my $exp = {"A" => 0, "B" => 1, "C" => 1};
    
    lives_ok( sub{ Table::_decrement_name_indicies($href, $i) },
             "expected to live -- _decremenet_name_indicies" );
    is_deeply( $href, $exp, "_decrement_name_indicies()" );
}

# test drop row
{
    # create some test tables
    my $t = Table->new();
    my $href = {A => {a=>1, b=>2, c=>3}, B => {a=>3, b=>4, c=>5}};
    $t->load_from_href_href($href, ["A", "B"], ["a", "b", "c"]);
    
    throws_ok( sub{ $t->drop_row() },
              'MyX::Generic::Undef::Param',
              "caught - drop_row(undef)" );
    throws_ok( sub{ $t->drop_row("Y") },
              'MyX::Table::Row::UndefName',
              "caught - drop_row(Y)" );
    
    # drop row A
    lives_ok( sub{ $t->drop_row("A") },
             "expected to live -- drop_row(A)" );
    is( $t->get_row_count(), 1, "drop_row(A) -- get row count" );
    is( $t->has_row("A"), 0, "drop_row(A) -- has row A is false" );
    is( $t->get_row_index("B"), 0, "drop_row(A) -- get new B index" );
    is( $t->get_value_at("B","a"), 3, "drop_row(A) -- get value at (B,a)" );
    
    throws_ok( sub{ $t->get_value_at("A", "a") },
              'MyX::Table::Row::UndefName',
              "caught - drop_row(A) -- after dropping" );
    
    # When I drop all the rows I should get an empty table
    # So now that I dropped row A above I can try dropping row B
    lives_ok( sub{ $t->drop_row("B") },
             "expected to live -- drop_row(B)" );
    is( $t->get_row_count(), 0, "drop_row(B) -- get row count on empty table" );
    is( $t->get_col_count(), 0, "drop_row(B) -- get col count on empty table" );
}

# test drop col
{
    # create some test tables
    my $t = Table->new();
    my $href = {A => {a=>1, b=>2, c=>3}, B => {a=>3, b=>4, c=>5}};
    $t->load_from_href_href($href, ["A", "B"], ["a", "b", "c"]);
    
    throws_ok( sub{ $t->drop_col() },
              'MyX::Generic::Undef::Param',
              "caught - drop_col(undef)" );
    throws_ok( sub{ $t->drop_col("A") },
              'MyX::Table::Col::UndefName',
              "caught - drop_col(A)" );
    
    # drop col a
    lives_ok( sub{ $t->drop_col("a") },
             "expected to live -- drop_col(a)" );
    is( $t->get_col_count(), 2, "drop_col(a) -- get col count" );
    is( $t->has_col("a"), 0, "drop_col(a) -- has col a is false" );
    is( $t->get_col_index("b"), 0, "drop_col(a) -- get new b index" );
    is( $t->get_value_at("A","b"), 2, "drop_col(a) -- get value at (A,b)" );
    
    throws_ok( sub{ $t->get_value_at("A", "a") },
              'MyX::Table::Col::UndefName',
              "caught - drop_col(a) -- after dropping" );
    
    # What happens when I drop all the cols from the Table
    # So now that I dropped col a above I can try dropping cols b and c
    lives_ok( sub{ $t->drop_col("b") },
             "expected to live -- drop_col(b)" );
    lives_ok( sub{ $t->drop_col("c") },
             "expected to live -- drop_col(c)" );
    is( $t->get_row_count(), 0, "drop_col() -- get row count on empty table" );
    is( $t->get_col_count(), 0, "drop_col() -- get col count on empty table" );
}

# test is_empty
{
    my $t = Table->new();
    
    is( $t->is_empty(), 1, "is_empty() -- true" );
    
    my $href = {A => {a=>1, b=>2, c=>3}, B => {a=>3, b=>4, c=>5}};
    $t->load_from_href_href($href, ["A", "B"], ["a", "b", "c"]);
    
    is( $t->is_empty(), 0, "is_empty() -- false" );
}

# test _count_end_seps -- function I use when their are trailing seps (ie
# empty cells)
{
    is( Table::_count_end_seps("1,2,3", ","), 0, "_count_end_seps(0)" );
    is( Table::_count_end_seps("1,2,", ","), 1, "_count_end_seps(1)" );
    is( Table::_count_end_seps("1,,", ","), 2, "_count_end_seps(2)" );
}

# test when there are missing values
{
    my ($fh, $filename) = tempfile();
    _make_tbl_file_missing_vals($fh);
    lives_ok( sub{ $table->load_from_file($filename, ",") },
             "expected to live -- load_from_file() -- missing values" );
}


###############
# Helper Subs #
###############
sub _make_tbl_file_c5 {
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

sub _make_tbl_file_c4 {
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

sub _make_tbl_file_c3 {
    my ($fh) = @_;
    
    # there is a text version of this tree at the bottom
    
    my $str = "A,B,C,D,E
0,3,3,5,5
2,0,3,5,5
3,3,0,4,4
5,5,4,0,2
5,5,4,2,0";

    print $fh $str;
    
    close($fh);
    
    return 1;
}

sub _make_tbl_file_c2 {
        my ($fh) = @_;
    
    # In this format there are no headers given (ie no col names)
    
    # there is a text version of this tree at the bottom
    
    my $str = "M,0,3,3,5,5
N,2,0,3,5,5
O,3,3,0,4,4
P,5,5,4,0,2
Q,5,5,4,2,0";

    print $fh $str;
    
    close($fh);
    
    return 1;
}

sub _make_tbl_file_c1 {
    my ($fh) = @_;
    
    # there is a text version of this tree at the bottom
    
    my $str = "0,3,3,5,5
2,0,3,5,5
3,3,0,4,4
5,5,4,0,2
5,5,4,2,0";

    print $fh $str;
    
    close($fh);
    
    return 1;
}

sub _make_tbl_file_c1_comm {
    my ($fh) = @_;
    
    # there is a text version of this tree at the bottom
    
    my $str = "# a comment line
0,3,3,5,5
2,0,3,5,5
3,3,0,4,4
# an inner comment
5,5,4,0,2
5,5,4,2,0";

    print $fh $str;
    
    close($fh);
    
    return 1;
}

sub _make_tbl_file_c4_sb { # sb stand for skip_before
    my ($fh) = @_;
    
    # there is a text version of this tree at the bottom
    
    my $str = "this line should be skipped
A,B,C,D,E
M,0,3,3,5,5
N,2,0,3,5,5
O,3,3,0,4,4
P,5,5,4,0,2
Q,5,5,4,2,0";

    print $fh $str;
    
    close($fh);
    
    return 1;
}

sub _make_tbl_file_c4_empty_line {
    my ($fh) = @_;
    
    # there is a text version of this tree at the bottom
    
    my $str = "A,B,C,D,E
M,0,3,3,5,5
N,2,0,3,5,5
O,3,3,0,4,4
P,5,5,4,0,2
Q,5,5,4,2,0
    ";

    print $fh $str;
    
    close($fh);
    
    return 1;
}

sub _make_tbl_file_missing_vals {
    my ($fh) = @_;
    
    # there is a text version of this tree at the bottom
    
    my $str = "A,B,C,D,E
M,0,3,,5,5
N,2,0,3,5,
O,,3,0,4,4
P,5,5,4,,
Q,5,5,4,3,4";

    print $fh $str;
    
    close($fh);
    
    return 1;
}

use strict;
use warnings;

use Test::More tests => 173;
use Test::Exception;
use MyX::Table;

# others to include
use File::Temp qw/ tempfile tempdir /;

BEGIN { use_ok( 'Table' ); }
BEGIN { use_ok( 'MyX::Table'); }


# helper subroutines
sub _make_tbl_file;



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
}

# test _set_sep
{
    is( Table::_set_sep(","), ",", "_set_sep(,)" );
    is( Table::_set_sep(), "\t", "_set_sep()" );
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
    
    
    ####
    # test using the second valid file format which includes a header for the
    # row names
    ($fh, $filename) = tempfile();
    _make_tbl_file2($fh);
     lives_ok( sub{ $table->load_from_file($filename, ",") },
             "expected to live -- load_from_file()" );
    
    # check the names to make sure they were set correctly
    is_deeply( $table->get_row_names(), ["M", "N", "O", "P", "Q"],
              "load_from_file -- look at row names" );
    is_deeply( $table->get_col_names(), ["A", "B", "C", "D", "E"],
              "load_from_file -- look at col names" );
    
    is( $table->get_row_names_header(), "RowNames",
       "load_from_file - row names header v2" );
    is( $table->has_row_names_header(), 1,
       "load_from_file -- has_row_names_header v2" );
    
    # reset to use the version 1 table
    ($fh, $filename) = tempfile();
    _make_tbl_file($fh);
    $table->load_from_file($filename, ",");
}

# test _load_from_href_href
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

# test _order
{
    # IMPORTANT!!! -- the _order function is not finished or tested!
    my $tbl;
    my $href = {"A" => {"a" => 1, "b" => 2}, "B" => {"a" => 3, "b" => 4}};
    ;
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
}

# test save
{
    # these tests could be more robust.  right now it simply tests
    # that a file was created and non-empty
    throws_ok( sub{ $table->save() },
              'MyX::Generic::Undef::Param', "save()" );
    
    my($fh, $filename) = tempfile();
    close($fh);
    lives_ok( sub{ $table->save($filename) },
             "expected to live -- save($filename)" );
    
    cmp_ok( -s $filename, ">", 0, "saved file is not empty" );
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
    _make_tbl_file($fh);
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
    _make_tbl_file($fh);
    lives_ok( sub{ $table->load_from_file($filename, ",") },
             "expected to live -- reset the table" );
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

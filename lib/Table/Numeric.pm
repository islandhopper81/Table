package Table::Numeric;

use MyX::Table;
use Table::Iter;
use MyX::Table::Iter;
use parent qw(Table);

use warnings;
use strict;
use Carp;
use Readonly;
use Class::Std::Utils;
use Array::Utils qw(:all);
use Scalar::Util qw(looks_like_number);
use List::MoreUtils qw(any);
use Log::Log4perl qw(:easy);
use Log::Log4perl::CommandLine qw(:all);
use MyX::Generic;
use version; our $VERSION = qv('0.0.1');
use UtilSY 0.0.2 qw(:all);

# set up the logging environment
my $logger = get_logger();

{
	# Usage statement
	Readonly my $NEW_USAGE => q{ new()};

	# Attributes #

	
	# Getters #
	sub min;
	sub max;

	# Setters #


	# Others #
	sub aggregate;
	
	



	###############
	# Constructor #
	###############
	sub new {
		my ($class, $arg_href) = @_;

		# Croak if calling new on already blessed reference
		croak 'Constructor called on existing object instead of class'
			if ref $class;
		
		# call the parent contructor
		my $new_obj = $class->SUPER::new($arg_href);

		return $new_obj;
	}

	###########
	# Getters #
	###########
	sub min {
		my ($self) = @_;
		
		my $tbl_iter = Table::Iter->new({table => $self});
		my $min;

		while ( $tbl_iter->has_next_value() ) {
			my $val = $tbl_iter->get_next_value();
			
			if ( ! is_defined($min) ) {
				$min = $val;
			}
			elsif ( $min > $val ) {
				$min = $val;
			}
		}
		
		return($min);
	}
	
	sub max {
		my ($self) = @_;
		
		my $tbl_iter = Table::Iter->new({table => $self});
		my $max;

		while ( $tbl_iter->has_next_value() ) {
			my $val = $tbl_iter->get_next_value();
			
			if ( ! is_defined($max) ) {
				$max = $val;
			}
			elsif ( $max < $val ) {
				$max = $val;
			}
		}
		
		return($max);
	}

	###########
	# Setters #
	###########
	
	
	##########
	# Others #
	##########
	sub aggregate {
		my ($self, $grp_aref) = @_;
		
		# NOTE: this only aggregates by rows.  To aggregate by columns you can
		#		transpose the matrix using the transpose() function, and then
		#		call aggregate().
		
		# some parameter checks
		check_defined($grp_aref, "grp_aref");
		check_ref($grp_aref, "ARRAY");
		
		# make sure the length of grps is the same as the number of rows in
		# the current table (ie self)
		if ( scalar @{$grp_aref} != $self->get_row_count() ) {
			MyX::Table::BadDim->throw(
				error => "grp_aref length and number of row names does NOT match",
				dim => "Col"
			);
		}
		
		# create a new table that will be the aggregated table
		my $new_tbl = Table->new();
		$new_tbl->_set_col_count($self->get_col_count());
		$new_tbl->_set_col_names($self->get_col_names());
		# the row names will be the values in the grp_aref
		
		# do the aggregation
		my $i = 0;  # current index of grp_aref
		my $new_val;
		foreach my $r ( @{$self->get_row_names} ) {
			my $grp_name = $grp_aref->[$i];
			if ( $new_tbl->has_row($grp_name) ) {
				# sum with the current row
				foreach my $c ( @{$self->get_col_names()} ) {
					$new_val = $self->get_value_at($r, $c) +
							   $new_tbl->get_value_at($grp_name, $c);
					$new_tbl->set_value_at($grp_name, $c, $new_val)
				}
			}
			else {
				# add the row
				my @row = @{$self->get_row($r)};
				$new_tbl->add_row($grp_name, \@row, $self->get_col_names());
			}
			$i++;
		}
		
		return($new_tbl);
	}
	
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Table - Object for storing and operating on a 2D table


=head1 VERSION

This document describes Table version 0.0.1


=head1 SYNOPSIS

    use Table;
	
	# create an empty table object
	my $table = Table->new();

	# load the table from a file
	$table->load_from_file("my_table.txt", "\t");
	
	# get the number rows and columns
	my $row_count = $table->get_row_count();
	my $col_count = $table->get_col_count();
	
	# get an array reference of row and column names
	my $row_names_aref = $table->get_row_names();
	my $col_names_aref = $table->get_col_names();
	
	# get the value at position in the matrix given by the row,col names
	my $val = $table->get_value_at($row_name, $col_name);
	
	# get an array reference of values for an entire row or column
	my $row_vals_aref = $table->get_row($row_name);
	my $col_vals_aref = $table->get_col($col_name);
	
	# save the table to a tab delimited file
	$table->save("output_table.txt", "\t");
	
	# save the table to a CSV file
	$table->save("output_table.txt", ",");
	
	# print the table tab delimited string
	$table->to_str("\t");
	
	# print the CSV string
	$table->to_str(",");
	
	# add a row to a table
	# NOTE: the values must be in the same order as the columns in the table
	my $row_vals_aref = [1,2,3,4,5];
	$table->add_row("new_row", $row_vals_aref);
	
	# add a row to a table where the values are in a different order than the
	# columns in the table.  This is the safest way to use the add_row method
	my $row_vals_aref = [1,2,3,4,5];
	my $row_names_aref = ["A", "B", "C", "D", "E"];
	$table->add_row("new_row", $row_vals_aref, $row_names_aref);
	
	# add a column using the method add_col by the same pattern as add_row
	
	# merge two tables
	$merged_tbl = $tbl1->merge({
		y_tbl => $tbl2,
		all_x => "T",
		all_y => "T"
	})
	
	# order by column
	my $numeric = 1; # TRUE
	my $decending = 1; # TRUE
	$table->order($col_name, $numeric, $decending);
  
  
=head1 DESCRIPTION

This module is an object for storing and opperating on tables (ie 2D matrix).
The data structure is implemented as an array of arrays.  The column and row
names are stored in hashes where the value associated with each name is the
index at which it is found in the array.  This allows fast access via the column
and row names.  The column names should be unique and the row names should be
unique.  In other words, there cannot be two rows with the name "A".  Similarly,
there cannot be two columns with the name "A".  There can be one column named
"A" and one row names "A" in the same table.

There are two recommend ways to populate a table object:

1) load_from_file -- this function parses through a plain text file to populate
the table object.  The first row should be the column headers.  The row names
can have a header value.  Each row after the header line should have a name as
the first value.  The sep option can be used to specify a delimiter for your
file (ie "\t", ",", etc).  This is the recommended and most simple way to
populate a table object.

2) load_from_href_href -- in Perl a table with column and row names can be
stored as hash reference of hash references.  If your data is in this format
the load_from_href_href function assumes the first level of the hash
reference corresponds with the rows.

3) add_row (or add_col) -- rows (or columns) can be iteratively added.  This
requires the row and column names to be set previously.  So you basically create
a table object, set the row and column names, then iteratively add either the
rows or columns.  This approach is not recommended as it has not be thoroughly
tested.

It is important to note that the set_value_at function cannot currently be used
to populate a new table.  It can only be used to edit existing values in a
table.

Once the table has been created values can be viewed or edited individually, the
table can be printed, the table can be merged with another table, the table can
be transposed, etc.  See the methods below for descriptions of operations that
can be done on Table objects.

The Table object is stored as a 2-d array.  This 2-d array can be queried and
edited using the described methods in conjuction with the row and column names.
Each column name is linked the index of the corresponding column values found in
the 2-d array.  The column names are also linked to an ordering.  This allows
the column order to change without actually changing the structure of the 2-d
array.  Therefore with the order subroutine is invoked the column name ordering
attributes are changed, but the 2-d table remains unchanged.  Then if the Table
is printed it is output by the specidied order.

=head1 CONFIGURATION AND ENVIRONMENT
  
Table requires no configuration files or environment variables.


=head1 DEPENDENCIES

MyX::Table
warnings
strict
Carp
Readonly
Class::Std::Utils
Array::Utils qw(:all)
Scalar::Util qw(looks_like_number)
List::MoreUtils qw(any)
Log::Log4perl qw(:easy)
Log::Log4perl::CommandLine qw(:all)
MyX::Generic
version our $VERSION = qv('0.0.1')


=head1 INCOMPATIBILITIES

None reported.


=head1 METHODS

=over
	
	# Constructor #
	new
	
	# Getters #
	sub get_row_count;
	sub get_col_count;
	sub get_row_names;
	sub get_col_names;
	sub get_value_at;
	sub get_value_at_fast;
	sub get_row;
	sub get_col;
	sub get_row_index;
	sub get_col_index;
	sub get_row_names_header;

	# Setters #
	sub set_value_at;
	sub _set_row_count;
	sub _set_col_count;
	sub _set_row_names;
	sub _set_col_names;
	sub _set_row_names_header;

	# Others #
	sub load_from_file;
	sub load_from_href_href;
	sub order;
	sub save;
	sub to_str;
	sub add_row;
	sub _add_row_checks;
	sub add_col;
	sub _add_col_checks;
	sub drop_row;
	sub _drop_row_checks;
	sub drop_col;
	sub _drop_col_checks;
	sub _decrement_name_indicies;
	sub merge;
	sub transpose;
	sub reset;
	sub copy;
	sub has_row;
	sub has_col;
	sub has_row_names_header;
	sub is_empty;
	sub _check_header_format;
	sub _aref_to_href;
	sub _check_file;
	sub _set_sep;
	sub _check_row_name;
	sub _check_col_name;
	sub _check_defined;

=back

=head1 METHODS DESCRIPTION

=head2 new

	Title: new
	Usage: Table->new();
	Function: Initializes an empty Table object
	Returns: Table
	Args: NA
	Throws: NA
	Comments: When this method is called the Table object is completely empty.
			  It can be populated using one of the 3 methods described in the
			  description.
	See Also: NA
	
=head2 get_row_count

	Title: get_row_count
	Usage: $obj->get_row_count()
	Function: Returns the total number of rows in the Table object
	Returns: int
	Args: NA
	Throws: NA
	Comments: NA
	See Also: NA
	
=head2 get_col_count

	Title: get_col_count
	Usage: $obj->get_col_count()
	Function: Returns the total number of columns in the Table object
	Returns: int
	Args: NA
	Throws: NA
	Comments: NA
	See Also: NA
	
=head2 get_row_names

	Title: get_row_names
	Usage: $obj->get_row_names($by_index)
	Function: Returns the row names in the order of their index
	Returns: aref
	Args: -by_index => an optional booling indicating to get the row names
	                   ordered by their index in the actual table and NOT their
					   defined sorted order
	Throws: NA
	Comments: Technically the rows can also be ordered by a column, but the
			  order subroutine does not currently include that functionality.
			  So calling get_row_names with $by_index = 1 (ie TRUE) will
			  always give you the same order.  Of course this will change when
			  I implement the ability to order by a given row in the order
			  subroutine.
	See Also: NA
	
=head2 get_col_names

	Title: get_col_names
	Usage: $obj->get_col_names($by_index)
	Function: Returns the column names in the order of their index
	Returns: aref
	Args: -by_index => an optional booling indicating to get the column names
	                   ordered by their index in the actual table and NOT their
					   defined sorted order
	Throws: NA
	Comments: The table is stored as a 2-d array.  The column names can be
		      ordered by how they fall in the 2-d array table or how they are
			  sorted.  With a Table that has not invoked the order subroutine
			  these two name orders will be the same.
	See Also: NA
	
=head2 get_value_at

	Title: get_value_at
	Usage: $obj->get_value_at($row, $col)
	Function: Returns the value at a given row,column pair
	Returns: scalar (whatever value type is in the Table)
	Args: -row => row name
	      -col => col name
	Throws: MyX::Table::Row::UndefName
	        MyX::Table::Col::UndefName
	Comments: This function is not optimized for speed.  I should not be used to
	          iterate over very large tables.  For iterating over the table use
			  a Table::Iter object.
	See Also: NA
	
=head2 get_value_at_fast

	Title: get_value_at_fast
	Usage: $obj->get_value_at_fast($r, $c)
	Function: Returns the value at a given row,column pair
	Returns: scalar (whatever value type is in the Table)
	Args: -r => row index
	      -c => col index
	Throws: NA
	Comments: WARNING!!  This method should not be called directly; treat it as
	          private.  It does not do error check (ie to see if the row and col
			  indicies are valid).  This method is called from Table::Iter.  To
			  get an individual value from the table use the get_value_at()
			  function.  To iterate over the table use a Table::Iter object.
	See Also: get_value_at()
			  Table::Iter
	
=head2 get_row

	Title: get_row
	Usage: $obj->get_row($row)
	Function: Returns the row values
	Returns: aref
	Args: -row => row name
	Throws: MyX::Table::Row::UndefName
	Comments: NA
	See Also: NA
	
=head2 get_col

	Title: get_col
	Usage: $obj->get_col($col)
	Function: Returns the col values
	Returns: aref
	Args: -col => col name
	Throws: MyX::Table::Col::UndefName
	Comments: This function is not optimized for speed.  Because the underlying
	          data structure is a 2-D array where the first dimension is rows
			  this function requires a for loop to go through each row and get
			  each value for the given column.  This will only be a problem on
			  very large tables.
	See Also: NA
	
=head2 get_row_index

	Title: get_row_index
	Usage: $obj->get_row_index($row)
	Function: Returns the row index
	Returns: int
	Args: -row => row name
	Throws: MyX::Table::Row::UndefName
	Comments: NA
	See Also: NA
	
=head2 get_col_index

	Title: get_col_index
	Usage: $obj->get_col_index($col)
	Function: Returns the col index
	Returns: int
	Args: -col => col name
	Throws: MyX::Table::Col::UndefName
	Comments: NA
	See Also: NA
	
=head2 get_row_names_header

	Title: get_row_names_header
	Usage: $obj->get_row_names_header()
	Function: Returns the row names header if it is set
	Returns: str or undef
	Args: NA
	Throws: NA
	Comments: The row names header is not required.  In the case where it is not
	          set this function returns undef
	See Also: NA
	
=head2 change_row_name

	Title: change_row_name
	Usage: $obj->change_row_name($current, $new)
	Function: Changes a row name
	Returns: 1 on success
	Args: -current => current row name
	      -new => new row name
	Throws: MyX::Table::Row::UndefName
	Comments: NA
	See Also: NA

=head2 change_col_name

	Title: change_col_name
	Usage: $obj->change_col_name($current, $new)
	Function: Changes a col name
	Returns: 1 on success
	Args: -current => current col name
	      -new => new col name
	Throws: MyX::Table::Col::UndefName
	Comments: NA
	See Also: NA
	
=head2 set_value_at

	Title: set_value_at
	Usage: $obj->set_value_at($row, $col, $val)
	Function: Sets the value at a given row,col location in the Table
	Returns: 1 on success
	Args: -row => row name
	      -col => col name
		  -val => value
	Throws: MyX::Table::Row::UndefName
	        MyX::Table::Col::UndefName
	Comments: NA
	See Also: NA
	
=head2 _set_row_count

	Title: _set_row_count
	Usage: $obj->_set_row_count($row_count)
	Function: Sets the row count
	Returns: 1 on success
	Args: -row_count => number of rows in the Table
	Throws: MyX::Generic::Digit::MustBeDigit
	        MyX::Generic::Digit::TooSmall
	Comments: PRIVATE!  Do NOT call this method outside of Table.pm.  $row_count
	          must be an integer greater than 0.
	See Also: NA
	
=head2 _set_col_count

	Title: _set_col_count
	Usage: $obj->_set_col_count($col_count)
	Function: Sets the col count
	Returns: 1 on success
	Args: -col_count => number of cols in the Table
	Throws: MyX::Generic::Digit::MustBeDigit
	        MyX::Generic::Digit::TooSmall
	Comments: PRIVATE!  Do NOT call this method outside of Table.pm.  $col_count
	          must be an integer greater than 0.
	See Also: NA
	
=head2 _set_row_names

	Title: _set_row_names
	Usage: $obj->_set_row_names($row_names_aref)
	Function: Sets the row names
	Returns: 1 on success
	Args: -row_names_aref => array reference of row names
	Throws: MyX::Table::BadDim
	        MyX::Table::NamesNotUniq
	Comments: PRIVATE!  Do NOT call this method outside of Table.pm.
	          $row_names_aref must have the same number of names as the number
			  of rows in the Table AND the row names must be unique (ie no
			  repeated names)
	See Also: NA
	
=head2 _set_col_names

	Title: _set_col_names
	Usage: $obj->_set_col_names($col_names_aref)
	Function: Sets the col names
	Returns: 1 on success
	Args: -col_names_aref => array reference of col names
	Throws: MyX::Table::BadDim
	        MyX::Table::NamesNotUniq
	Comments: PRIVATE!  Do NOT call this method outside of Table.pm.
	          $col_names_aref must have the same number of names as the number
			  of columns in the Table AND the column names must be unique (ie no
			  repeated names)
	See Also: NA
	
=head2 _set_row_names_header

	Title: _set_row_names_header
	Usage: $obj->_set_row_names_header($row_names_header)
	Function: Sets the row names header
	Returns: 1 on success
	Args: -row_names_header => row names header string
	Throws: NA
	Comments: If $row_names_header is not provided this is set to undef.
	See Also: NA
	
=head2 load_from_href_href

	Title: load_from_href_href
	Usage: $obj->load_from_href_href($href, $row_names_aref, $col_names_aref)
	Function: Loads the data from an href of hrefs
	Returns: 1 on success
	Args: -href => hash reference containing hash references
	      -row_names_aref => array reference of row names
		  -col_names_aref => array reference of column names
	Throws: MyX::Table::BadDim
	        MyX::Table::NamesNotUniq
	Comments: This method loads the data into the Table object from a hash
	          reference of hash references object.  The first level of the hash
			  reference should be the rows and the second is columns.  The data
			  are added to the Table object using a command like this:
			  $href->{$row}->{$col}.  
	See Also: NA
	
=head2 load_from_file

	Title: load_from_file
	Usage: $obj->load_from_file($file, $sep)
	Function: Loads the data from a delimited file
	Returns: 1 on success
	Args: -file => path to file
	      -sep => delimiter string
	Throws: MyX::Generic::File::CannotOpen
	        MyX::Table::BadDim
	        MyX::Table::NamesNotUniq
			MyX::Generic::Digit::MustBeDigit
	        MyX::Generic::Digit::TooSmall
	Comments: This is the recommended method to load data into a Table object.
	          It assumes the first line is the column names and the first
			  column is the row names.  The row names column (ie the first
			  column) may have a name, but it is not required.
	See Also: NA
	
=head2 order

	Title: order
	Usage: $obj->order($col_name, $numeric, $decreasing)
	Function: Orders the table based on a single column
	Returns: 1 on success
	Args: -col_name => name of column by which to order
		  -numeric => bool indicating to do a numeric sort
		  -decreasing => bool indicating to do a decreasing sort
	Throws: MyX::Table::Col::UndefName
	        MyX::Generic::Undef::Param
	Comments: By default $numeric is set to TRUE and decreasing is set to TRUE.
	
	           To Do:
				- Pass the parameters using a hash.  Currently if you want to
				  set decreasing you also MUST set numeric.
				- add ability to sort by a given row
				
			  Currently a Table can only be sorted by a given column.  It cannot
			  be sorted by a given row.  Update the comments in the
			  get_col_names and get_row_names subroutines if this changes.
	See Also: NA
	
=head2 save

	Title: save
	Usage: $obj->save($file, $sep)
	Function: Outputs the Table as text in the given file
	Returns: 1 on success
	Args: -file => path to output file
	      -sep => delimiter string
	Throws: MyX::Generic::File::CannotOpen
	Comments: The default sep value is "\t".
	See Also: NA
	
=head2 to_str

	Title: to_str
	Usage: $obj->to_str($sep)
	Function: Returns the Table as a string
	Returns: str
	Args: -sep => delimiter string
	Throws: NA
	Comments: The default sep value is "\t".
	See Also: NA
	
=head2 add_row

	Title: add_row
	Usage: $obj->add_row($row_name, $row_vals_aref, $col_names_aref)
	Function: Adds a row to the Table
	Returns: 1 on success
	Args: -row_name => name of row
	      -row_vals_aref => aref with row values
		  -col_names_aref => aref with column name for each row value
	Throws: MyX::Table::Col::UndefName
	Comments: This function assumes the each row element is in the correct order
	          meaning that the row values for this row correspond with the
			  columns alread in the Table.  If you want to add a row that where
			  the values are not in the same order as the columns in the Table
			  use the col_names_aref parameter.  When the col_names_aref
			  parameter is provided, each value in the row_vals_aref will be
			  added to the table column that corresponds to the column name at
			  the same index in col_names_aref.  For example, if the table
			  columns include A, B, C, D, but the values in row_vals_aref
			  are ordered D, C, B, A then by passing a col_names_aref with
			  D, C, B, A the values will be added in the correct order.  In the
			  case when the Table is empty col_names_aref becomes a required
			  parameter.  Note that if the row_name is already in the table an
			  error will be thrown.  You cannot overwrite an existing row using
			  this method.
	See Also: NA
	
=head2 _add_row_checks

	Title: _add_row_checks
	Usage: $obj->_add_row_checks($row_name, $row_vals_aref, $col_names_aref)
	Function: Checks the parameters that are passed to add_row
	Returns: 1 on success
	Args: -row_name => name of row
	      -row_vals_aref => aref with row values
		  -col_names_aref => aref with column name for each row value
	Throws: MyX::Table::Row::NameInTable
	        MyX::Generic::Digit::MustBeDigit
	        MyX::Generic::Digit::TooSmall
			MyX::Table::BadDim
	        MyX::Table::NamesNotUniq
			MyX::Generic::Ref::UnsupportedType
			MyX::Generic::Undef::Param
	Comments: This function is PRIVATE!  It should not be invoked by the average
	          user outside of Table.pm.  This functions checks the following:
			      - makes sure parameter values are defined
				  - makes sure the row name is not already in the table
				  - makes sure the row_vals_are is an aref
				  - makes sure the number of vals in row_vals_aref is equal to
				    the number of columns in the Table
				  - makes sure col_names_aref is an aref
				  - makes sure the number of names in col_names_aref is the same
				    as the column count
			  Also if the table is currently empty it will set the column count
			  and column names based on col_names_aref.  In the case when the
			  Table is empty col_names_aref becomes a required parameter.
	See Also: NA
	
=head2 add_col

	Title: add_col
	Usage: $obj->add_col($col_name, $col_vals_aref, $row_names_aref)
	Function: Adds a column to the Table
	Returns: 1 on success
	Args: -col_name => name of col
	      -col_vals_aref => aref with col values
		  -row_names_aref => aref with row name for each column value
	Throws: MyX::Table::Row::UndefName
	Comments: This function assumes the each col element is in the correct order
	          meaning that the col values for this col correspond with the
			  rows alread in the Table.  If you want to add a col where the
			  values are not in the same order as the rows in the Table use
			  the row_names_aref parameter.  When the row_names_aref parameter
			  is provided, each value in the col_vals_aref will be added to the
			  table row that corresponds to the row name at the same index
			  in row_names_aref.  For example, if the table rows include
			  A, B, C, D, but the values in col_vals_aref are ordered D, C, B, A
			  then by passing a row_names_aref with D, C, B, A the values will
			  be added in the correct order.  In the case when the Table is
			  empty row_names_aref becomes a required parameter. Note that if
			  the col_name is already in the table an error will be thrown.
			  You cannot overwrite an existing column using this method.
	See Also: NA
	
=head2 _add_col_checks

	Title: _add_col_checks
	Usage: $obj->_add_col_checks($col_name, $col_vals_aref, $row_names_aref)
	Function: Checks the parameters that are passed to add_col
	Returns: 1 on success
	Args: -col_name => name of col
	      -col_vals_aref => aref with col values
		  -row_names_aref => aref with row name for each row value
	Throws: MyX::Table::Col::NameInTable
	        MyX::Generic::Digit::MustBeDigit
	        MyX::Generic::Digit::TooSmall
			MyX::Table::BadDim
	        MyX::Table::NamesNotUniq
			MyX::Generic::Ref::UnsupportedType
			MyX::Generic::Undef::Param
	Comments: This function is PRIVATE!  It should not be invoked by the average
	          user outside of Table.pm.  This functions checks the following:
			      - makes sure parameter values are defined
				  - makes sure the col name is not already in the table
				  - makes sure the col_vals_are is an aref
				  - makes sure the number of vals in col_vals_aref is equal to
				    the number of rows in the Table
				  - makes sure row_names_aref is an aref
				  - makes sure the number of names in row_names_aref is the same
				    as the row count
			  Also if the table is currently empty it will set the row count
			  and row names based on row_names_aref.  In the case when the
			  Table is empty row_names_aref becomes a required parameter.
	See Also: NA
	
=head2 drop_row

	Title: drop_row
	Usage: $obj->drop_row($row_name)
	Function: Removes the given row from the table
	Returns: 1 on success
	Args: -row_name => name of row
	Throws: MyX::Table::Row::UndefName
			MyX::Generic::Undef::Param
	Comments: NA
	See Also: NA
	
=head2 _drop_row_checks

	Title: _drop_row_checks
	Usage: $obj->_drop_row_checks($row_name)
	Function: Removes the given row from the table
	Returns: 1 on success
	Args: -row_name => name of row
	Throws: MyX::Table::Row::UndefName
			MyX::Generic::Undef::Param
	Comments: This function is PRIVATE!  It should not be invoked by the average
	          user outside of Table.pm.  This functions checks the following:
			      - makes sure parameter values are defined
				  - makes sure the row exists in the table
	See Also: NA
	
=head2 drop_col

	Title: drop_col
	Usage: $obj->drop_col($row_name)
	Function: Removes the given col from the table
	Returns: 1 on success
	Args: -col_name => name of col
	Throws: MyX::Table::Col::UndefName
			MyX::Generic::Undef::Param
	Comments: NA
	See Also: NA
	
=head2 _drop_col_checks

	Title: _drop_col_checks
	Usage: $obj->_drop_col_checks($col_name)
	Function: Removes the given col from the table
	Returns: 1 on success
	Args: -col_name => name of col
	Throws: MyX::Table::Col::UndefName
			MyX::Generic::Undef::Param
	Comments: This function is PRIVATE!  It should not be invoked by the average
	          user outside of Table.pm.  This functions checks the following:
			      - makes sure parameter values are defined
				  - makes sure the col exists in the table
	See Also: NA
	
=head2 _decrement_name_indicies

	Title: _decrement_name_indicies
	Usage: _decrement_name_indicies($href, $i)
	Function: Adjusts the indicies in the row and col names hrefs after a row or
	          col is removed from the table
	Returns: 1 on success
	Args: -href => either the col or the row names href
	      -i => the index that was removed
	Throws: NA
	Comments: This function is PRIVATE!  It should not be invoked by the average
	          user outside of Table.pm.  This functions decrements the indicies
			  in the row or col name href.  Remember the row and col names are
			  stored as features in this object.  They are stored as hash
			  references where the key is the name and the value is the index
			  in the table.  When a row or col is removed this function
			  decrements the indicies of the rows (or cols) after the row (or
			  col) that was removed.
	See Also: drop_row
	          drop_col
	
=head2 merge

	Title: merge
	Usage: $obj->merge($params_href)
	Function: Merges two tables
	Returns: Table
	Args: -params_href => href of merging parameters (see Comments)
	Throws: MyX::Table::Col::NameInTable
	        MyX::Generic::Digit::MustBeDigit
	        MyX::Generic::Digit::TooSmall
			MyX::Table::BadDim
	        MyX::Table::NamesNotUniq
			MyX::Generic::Ref::UnsupportedType
			MyX::Generic::Undef::Param
	Comments: The params_href should have the following features:
	          params_href{y_tbl => Table,
			              all_x => boolean,
						  all_y => boolean}
			  The "x" value parameters correspond to calling Table object (ie
			  the table object that invokes the merge function.  The "y" value
			  parameters correspond to the other Table object.  So the y_tbl is
			  a Table object that will be mered with the calling table object
			  (ie. the "x" table).
			  
			  The outcome of merging depends on how these parameters are set.
			  When all_x and all_y are set to true the union of all rows and
			  columns are in the merged table.  When all_x is set to false only
			  the rows that intersect with the rows in the y table are included
			  in the final merged table.  Similarly, when all_y is set to false
			  only the rows that intersect with the rows in the y table are
			  included in the final merged table.  The columns in the resulting
			  merged table are ALWAYS the union of columns in x and y.  When
			  there are two columns with the same name and "_y" is appended to
			  the column from the "y" table to make it a unique header value.
			  Remember, a Table must have unique column names and unique row
			  names.
	See Also: NA
	
=head2 _check_merge_params

	Title: _check_merge_params
	Usage: _check_merge_params($params_href)
	Function: Checks the merge parameters for errors
	Returns: Table
	Args: -params_href => href of merging parameters (see Comments)
	Throws: MyX::Table::Col::NameInTable
	        MyX::Generic::Digit::MustBeDigit
	        MyX::Generic::Digit::TooSmall
			MyX::Table::BadDim
	        MyX::Table::NamesNotUniq
			MyX::Generic::Ref::UnsupportedType
			MyX::Generic::Undef::Param
	Comments: This function is PRIVATE!  It should not be invoked by the average
	          user outside of Table.pm. The params_href should have the
			  following features:
	          params_href{y_tbl => Table,
			              all_x => boolean,
						  all_y => boolean}
			  This checks to make sure y_tbl is a Table object, makes sure all_x
			  is defined and is a boolean, and makes sure all_y is defined and
			  is a boolean.
	See Also: Table::merge

=head2 transpose

	Title: transpose
	Usage: $obj->transpose()
	Function: Transposes the table
	Returns: 1 on success
	Args: NA
	Throws: NA
	Comments: NA
	See Also: NA
	
=head2 reset

	Title: reset
	Usage: $obj->reset()
	Function: Clears all the data in the object
	Returns: 1 on success
	Args: NA
	Throws: NA
	Comments: Warning: once you call this method there is no going backward.
	          All the data that was contained in the table is perminantly
			  deleted.
	See Also: NA

=head2 copy

	Title: copy
	Usage: my $copy = $obj->copy()
	Function: Makes a copy of the object
	Returns: Table object
	Args: NA
	Throws: NA
	Comments: NA 
	See Also: NA

=head2 has_row

	Title: has_row
	Usage: $obj->has_row($row)
	Function: Checks if the table object has the specified row
	Returns: bool (0 | 1)
	Args: -row => name of the row to look for
	Throws: MyX::Generic::Undef::Param
	Comments: NA 
	See Also: NA

=head2 has_col

	Title: has_col
	Usage: $obj->has_col($col)
	Function: Checks if the table object has the specified col
	Returns: bool (0 | 1)
	Args: -col => name of the col to look for
	Throws: MyX::Generic::Undef::Param
	Comments: NA 
	See Also: NA

=head2 has_row_names_header

	Title: has_row_names_header
	Usage: $obj->has_row_names_header()
	Function: Checks if the table object has a row name header string
	Returns: bool (0 | 1)
	Args: NA
	Throws: NA
	Comments: NA 
	See Also: NA
	
=head2 is_empty

	Title: is_empty
	Usage: $obj->is_empty()
	Function: Checks if the table object is empty
	Returns: bool (0 | 1)
	Args: NA
	Throws: NA
	Comments: This function only looks at the col and row counts.  If either of
			  those is at 0 then the table must be empty.
	See Also: NA

=head2 _check_header_format

	Title: _check_header_format
	Usage: $obj->_check_header_format($first_line_vals_count)
	Function: Checks if one of the column headers is the row name header
	Returns: bool (0 | 1)
	Args: -first_line_vals_count => number of values in first line
	Throws: NA
	Comments: This function is PRIVATE!  It should not be invoked by the average
	          user outside of Table.pm.  It checks the first non-header line in
			  the file to deterimine if the first value in the column headers
			  is actually the row header name.  The row header name is optional.
			  If the row header name is provided it is removed from the column
			  names array and stored in the row_names_header attribute.
	See Also: NA
	
=head2 _aref_to_href

	Title: _aref_to_href
	Usage: _aref_to_href($aref)
	Function: Transforms an array reference into a hash reference
	Returns: hash ref
	Args: -aref => an array reference
	Throws: NA
	Comments: This function is PRIVATE!  It should not be invoked by the average
	          user outside of Table.pm.  The value associated with each key in
			  the returned hash reference is the index at which that key was
			  found in the given array reference.
	See Also: NA
	
=head2 _check_file

	Title: _check_file
	Usage: _check_file($file)
	Function: Runs some checks on a file
	Returns: 1 on success
	Args: -file => path to a file
	Throws: MyX::Generic::Undef::Param
	        MyX::Generic::DoesNotExist::File
			MyX::Generic::File::Empty
	Comments: This function is PRIVATE!  It should not be invoked by the average
	          user outside of Table.pm.  This function will throw errors if the
			  file parameter is not defined, if the file does not exist, or if
			  the file is empty.
	See Also: NA
	
=head2 _set_sep

	Title: _set_sep
	Usage: _set_sep($sep)
	Function: Checks the seperater value to make sure it is defined
	Returns: str
	Args: -sep => seperater string
	Throws: NA
	Comments: This function is PRIVATE!  It should not be invoked by the average
	          user outside of Table.pm.  If the sep parameter is not defined
			  the defualt is returned.  Currently the default is set to "\t".
	See Also: NA
	
=head2 _check_row_name

	Title: _check_row_name
	Usage: _check_row_name($row)
	Function: Checks a row name to ensure it is defined and exists in the table
	Returns: 1 on success
	Args: -row => row name
	Throws: MyX::Generic::Undef::Param
	        MyX::Table::Row::UndefName
	Comments: This function is PRIVATE!  It should not be invoked by the average
	          user outside of Table.pm.
	See Also: NA
	
=head2 _check_col_name

	Title: _check_col_name
	Usage: _check_col_name($row)
	Function: Checks a col name to ensure it is defined and exists in the table
	Returns: 1 on success
	Args: -col => column name
	Throws: MyX::Generic::Undef::Param
	        MyX::Table::Col::UndefName
	Comments: This function is PRIVATE!  It should not be invoked by the average
	          user outside of Table.pm.
	See Also: NA
	
=head2 _check_defined

	Title: _check_defined
	Usage: _check_defined($val $val_name)
	Function: Checks if a value is defined
	Returns: 1 on success
	Args: -val => a value
	      -val_name => value name (for printing error messages)
	Throws: MyX::Generic::Undef::Param
	Comments: This function is PRIVATE!  It should not be invoked by the average
	          user outside of Table.pm.
	See Also: NA
	
=head2 _is_aref

	Title: _is_aref
	Usage: _is_aref($aref $name)
	Function: Checks if a value is an array reference
	Returns: 1 on success
	Args: -aref => array reference
	      -name => name of the aref variable (for printing error messages)
	Throws: MyX::Generic::Ref::UnsupportedType
	Comments: This function is PRIVATE!  It should not be invoked by the average
	          user outside of Table.pm.
	See Also: NA
	
=head2 _to_bool

	Title: _to_bool
	Usage: _to_bool($val)
	Function: Converts a boolean-like value to either 0 or 1
	Returns: bool
	Args: -val => a boolean-like value
	Throws: NA
	Comments: This function is PRIVATE!  It should not be invoked by the average
	          user outside of Table.pm.  Boolean-like values include:  Y, YES,
			  Yes, y, yes, T, t, TRUE, true, True.  Anything that is not
			  included in that list is considered false (ie 0).
	See Also: NA

=head1 BUGS AND LIMITATIONS


No bugs have been reported.

Please report any bugs or feature requests to
C<bug-table@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 TO DO

=head2 check what happens with row_name_header when adding rows
or columns and providing the third argument.

=head2 check for columns without correct number

When I read in the table there could be columns that are not square
with the rest of columns.

=head2 optimize reset function

I think there is a more efficient way to implement the reset function
that will explicenetly free up the memory.

=head2 a melt function

Similar to the melt function in R

=head2 an iterater function

Get each element in the table one at a time.  It might be useful to utilize the
melt function here.

=head2 make a table iterator object

for iterating through each element in the table.

=head1 AUTHOR

Scott Yourstone  C<< scott.yourstone81@gmail.com >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013, Scott Yourstone
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met: 

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer. 
2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution. 

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

The views and conclusions contained in the software and documentation are those
of the authors and should not be interpreted as representing official policies, 
either expressed or implied, of the FreeBSD Project.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.


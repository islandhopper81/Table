package Table;

use MyX::Table;

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

# set up the logging environment
my $logger = get_logger();

{
	# Usage statement
	Readonly my $NEW_USAGE => q{ new()};
	Readonly::Scalar my $SEP => "\t";

	# Attributes #
	my %row_count_of;
	my %col_count_of;
	my %row_names_of; # a href
	my %col_names_of; # a href
	my %mat_of;
	
	# Getters #
	sub get_row_count;
	sub get_col_count;
	sub get_row_names;
	sub get_col_names;
	sub get_value_at;
	sub get_row;
	sub get_col;
	sub get_row_index;
	sub get_col_index;

	# Setters #
	sub _set_row_count;
	sub _set_col_count;
	sub _set_row_names;
	sub _set_col_names;

	# Others #
	sub load_from_file;
	sub load_from_href_href;
	sub _order; # to do
	sub save;
	sub to_str;
	sub add_row;
	sub _add_row_checks;
	sub add_col;
	sub _add_col_checks;
	sub merge;
	sub _check_merge_params;
	sub transpose; # to do
	sub reset; # to do
	sub has_row;
	sub has_col;
	sub _aref_to_href;
	sub _check_file;
	sub _set_sep;
	sub _check_row_name;
	sub _check_col_name;
	sub _is_aref;
	sub _is_defined;
	sub _to_bool;
	
	



	###############
	# Constructor #
	###############
	sub new {
		my ($class, $arg_href) = @_;

		# Croak if calling new on already blessed reference
		croak 'Constructor called on existing object instead of class'
			if ref $class;

		# Make sure the required parameters are defined
		# right now there are NO required parameters
		#if ( any {!defined $_}
		#	) {
		#	MyX::Generic::Undef::Params->throw(
		#		error => 'Undefined parameter value',
		#		usage => $NEW_USAGE,
		#	);
		#}

		# Bless a scalar to instantiate an object
		my $new_obj = bless \do{my $anon_scalar}, $class;

		# Set Attributes
		$new_obj->_set_col_count(0);
		$new_obj->_set_row_count(0);

		return $new_obj;
	}

	###########
	# Getters #
	###########
	sub get_row_count {
		my ($self) = @_;
		
		return $row_count_of{ident $self};
	}
	
	sub get_col_count {
		my ($self) = @_;
		
		return $col_count_of{ident $self};
	}
	
	sub get_row_names {
		my ($self) = @_;
		
		# returns the names in an array ref as sorted by their index
		my $names_href = $row_names_of{ident $self};
		my @arr = sort { $names_href->{$a} <=> $names_href->{$b} } keys(%$names_href);
		
		return(\@arr);
	}
	
	sub get_col_names {
		my ($self) = @_;
		
		# returns the names in an array ref as sorted by their index
		my $names_href = $col_names_of{ident $self};
		my @arr = sort { $names_href->{$a} <=> $names_href->{$b} } keys(%$names_href);
		
		return(\@arr);
	}
	
	sub get_value_at {
		my ($self, $row, $col) = @_;
		
		# this function will likely be slow is you use it iteratively
		
		$self->_check_row_name($row);
		$self->_check_col_name($col);
		
		my $r = $self->get_row_index($row);
		my $c = $self->get_col_index($col);
		
		return($mat_of{ident $self}->[$r][$c]);
	}
	
	sub get_row {
		my ($self, $row) = @_;
		
		$self->_check_row_name($row);
		my $r = $self->get_row_index($row);
		
		return($mat_of{ident $self}->[$r]);
	}
	
	sub get_col {
		my ($self, $col) = @_;
		
		# NOTE: this is the slow one
		
		$self->_check_col_name($col);
		my $c = $self->get_col_index($col);
		
		my @col_arr = ();
		foreach my $row_aref ( @{$mat_of{ident $self}} ) {
			push @col_arr, $row_aref->[$c];
		}
		
		return(\@col_arr);
	}
	
	sub get_row_index {
		my ($self, $row) = @_;
		
		my $r = $row_names_of{ident $self}->{$row};
		
		return($r);
	}
	
	sub get_col_index {
		my ($self, $col) = @_;
		
		my $c = $col_names_of{ident $self}->{$col};
		
		return($c);
	}

	###########
	# Setters #
	###########
	sub change_row_name {
		my ($self, $old, $new) = @_;
		
		_is_defined($old, "old name");
		_is_defined($new, "new name");
		
		# check if the old name is in the table
		if ( ! $self->has_row($old) ) {
			MyX::Table::Col::UndefName->throw(
				error => "No such row name: $old"
			);
		}
		
		my $index = $row_names_of{ident $self}->{$old};
		$row_names_of{ident $self}->{$new} = $index;
		delete $row_names_of{ident $self}->{$old};
		
		return 1;
	}
	
	sub change_col_name {
		my ($self, $old, $new) = @_;
		
		_is_defined($old, "old name");
		_is_defined($new, "new name");
		
		# check if the old name is in the table
		if ( ! $self->has_col($old) ) {
			MyX::Table::Col::UndefName->throw(
				error => "No such column name: $old"
			);
		}
		
		my $index = $col_names_of{ident $self}->{$old};
		$col_names_of{ident $self}->{$new} = $index;
		delete $col_names_of{ident $self}->{$old};
		
		return 1;
	}
	
	sub _set_row_count {
		my ($self, $row_count) = @_;
		
		# check if the parameter is defined
		_is_defined($row_count, "row_count");

		# check if row_count is a number
		if ( ! looks_like_number($row_count) ) {
			MyX::Generic::Digit::MustBeDigit->throw(
				error => "row_count parameter must be a digit > 0"
			);
		}
		
		# make sure the number is >= 0
		if ( $row_count < 0 ) {
			MyX::Generic::Digit::TooSmall->throw(
				error => "row_count parameter must be a digit > 0"
			);
		}
		
		$row_count_of{ident $self} = $row_count;
		
		return 1;
	}
	
	sub _set_col_count {
		my ($self, $col_count) = @_;
		
		# check if the parameter is defined
		_is_defined($col_count, "col_count");
		
		# check if col_count is a number
		if ( ! looks_like_number($col_count) ) {
			MyX::Generic::Digit::MustBeDigit->throw(
				error => "col_count parameter must be a digit > 0"
			);
		}
		
		# make sure the number is >= 0
		if ( $col_count < 0 ) {
			MyX::Generic::Digit::TooSmall->throw(
				error => "col_count parameter must be a digit > 0"
			);
		}
		
		$col_count_of{ident $self} = $col_count;
		
		return 1;
	}

	sub _set_row_names {
		my ($self, $row_names_aref) = @_;
		
		# Rules: 
		# 1. the number of row names must match the number of rows
		# 2. the row names must be unique (ie no repeats)
		
		# check if the parameter is defined
		_is_defined($row_names_aref, "row_names_aref");
		
		# check rule 1
		if ( $self->get_row_count() != scalar @{$row_names_aref} ) {
			MyX::Table::BadDim->throw(
				error => "Col count and number of row names does NOT match",
				dim => "Col"
			);
		}
		
		# check rule 2
		my $row_names_href = _aref_to_href($row_names_aref);
		if ( $self->get_row_count() != scalar(keys %{$row_names_href}) ) {
			MyX::Table::NamesNotUniq->throw(
				error => "Col names not unique",
				dim => "Col"
			);
		}
		
		$row_names_of{ident $self} = $row_names_href;
		
		return 1;
	}
	
	sub _set_col_names {
		my ($self, $col_names_aref) = @_;
		
		# Rules: 
		# 1. the number of col names must match the number of cols
		# 2. the col names must be unique (ie no repeats)
		
		# check if the parameter is defined
		_is_defined($col_names_aref, "col_names_aref");
		
		# check rule 1
		if ( $self->get_col_count() != scalar @{$col_names_aref} ) {
			MyX::Table::BadDim->throw(
				error => "Col count and number of col names does NOT match",
				dim => "Col"
			);
		}
		
		# check rule 2
		my $col_names_href = _aref_to_href($col_names_aref);
		if ( $self->get_col_count() != scalar(keys %{$col_names_href}) ) {
			MyX::Table::NamesNotUniq->throw(
				error => "Col names not unique",
				dim => "Col"
			);
		}
		
		$col_names_of{ident $self} = $col_names_href;
		
		return 1;
	}
	
	##########
	# Others #
	##########
	sub load_from_href_href {
		my ($self, $href, $row_names_aref, $col_names_aref) = @_;
		
		# NOTE: I assume the first level in the href is rows
		
		_is_defined($href, "href");
		_is_defined($row_names_aref, "row names");
		_is_defined($col_names_aref, "col names");
		_is_aref($row_names_aref);
		_is_aref($col_names_aref);
		
		# Set the row names
		$self->_set_row_count(scalar @{$row_names_aref});
		$self->_set_row_names($row_names_aref);
		
		# Set the column names
		# NOTE: I assume here that each column has the same number of rows
		$self->_set_col_count(scalar @{$col_names_aref});
		$self->_set_col_names($col_names_aref);
		
		my @tbl = ();
		foreach my $row ( @{$row_names_aref} ) {
			my @row_arr = ();
			foreach my $col ( @{$col_names_aref} ) {
				push @row_arr, $href->{$row}->{$col};
			}
			push @tbl, \@row_arr
		}
		
		# set the matrix
		$mat_of{ident $self} = \@tbl;
		
		return 1;
	}
	
	sub load_from_file {
		my ($self, $file, $sep) = @_;
		
		_check_file($file);
		
		# set the sep
		$sep = _set_sep($sep);
		
		open my $IN, "<", $file or
			MyX::Generic::File::CannotOpen->throw(
				error => "Cannot read file",
				file_name => $file
			);
		
		# the first line should be the column headers
		# this sets the column counts and names
		chomp(my $headers = <$IN>);
		my @col_names = split(/$sep/, $headers);
		$self->_set_col_count(scalar @col_names);
		$self->_set_col_names(\@col_names);
		
		# read in the rows
		# take of the row names as the rows are input
		my @vals = ();
		my $row_name;
		my @row_names = ();
		my $i;
		my @tbl = ();
		foreach my $line ( <$IN> ) { 
			chomp $line;
			@vals = split(/$sep/, $line);
		
			$row_name = shift @vals;
			push @row_names, $row_name;
			$i = 0;
			my @row_arr = (); 
			foreach my $val ( @vals ) {
				push @row_arr, $val;
			}
			push @tbl, \@row_arr;
		}
		
		# set the row names
		$self->_set_row_count(scalar @row_names);
		$self->_set_row_names(\@row_names);
		
		# set the matrix
		$mat_of{ident $self} = \@tbl;
		
		return 1;
	}
	
	sub _order {
		my ($self) = @_;
		# IMPORTNAT!!!! --- This function is not finihsed or tested!
		
		# this function orders the table by the indicies in the row and
		# col names hashes
		
		my @ordered_rows = $self->get_row_names();
		my @ordered_cols = $self->get_col_names();
		my @tbl = ();
		foreach my $row ( @ordered_rows ) {
			my @row_arr = ();
			push @tbl, \@row_arr;
		}
		
		my $i = 0;
		my $j = 0;
		foreach my $row ( @ordered_rows ) {
			$j = 0;  # reset the col counter
			foreach my $col ( @ordered_cols ) {
				$tbl[$i][$j] = $self->get_value_at($row, $col);
				$j++;
			}
			$i++;
		}
		
		for ( my $i = 0; $i < scalar @ordered_rows; $i++ ) {
			for ( my $j = 0; $j < scalar @ordered_cols; $j++ ) {
				$tbl[$i][$j] = $self->get_value_at(@ordered_rows)
			}
		}
		
		$mat_of{ident $self} = \@tbl;
	}
	
	sub save {
		my ($self, $file, $sep) = @_;
		
		# NOTE: I assume that the matrix is already in order
		# 		ie the names index match the order in the 2d array
		
		# check if the file parameter is defined
		_is_defined($file, "file");
		
		$sep = _set_sep($sep);
		
		open my $OUT, ">", $file or
			MyX::Generic::File::CannotOpen->throw(
				error => "Cannot open file ($file) for writing"
			);
		
		print $OUT $self->to_str($sep);
		
		return 1;
	}
	
	sub to_str {
		my ($self, $sep) = @_;
		
		$sep = _set_sep($sep);
		
		my $str = "";
		
		# print the column headers
		$str = (join($sep, @{$self->get_col_names()}));
		$str .= "\n";
		
		# print the row names and each row in the matrix
		my $row_count = $self->get_row_count();
		my $row_names_aref = $self->get_row_names();
		my $mat_aref = $mat_of{ident $self};
		foreach my $row ( @{$row_names_aref} ) {
			$str .= $row . $sep;
			$str .= (join($sep, @{$self->get_row($row)}));
			$str .= "\n";
		}
		
		return($str);
	}
	
	sub add_row {
		my ($self, $row_name, $row_vals_aref, $col_names_aref) = @_;
		
		# NOTE: if row_names_aref is not provided the rows are
		# added in the order provided in the row_vals_aref
		
		# check the parameters
		$self->_add_row_checks($row_name, $row_vals_aref, $col_names_aref);
		
		# add the row in the order provided
		if ( ! defined $col_names_aref ) {
			# add the row
			push @{$mat_of{ident $self}}, $row_vals_aref;
			
			# save the name and index (which is the same as the current
			# number of rows) to the row names attribute
			$row_names_of{ident $self}->{$row_name} = $self->get_row_count();
			
			# increment the row count
			$self->_set_row_count($self->get_row_count() + 1);
		}
		else {
			# index the col names for the row that was passed in
			my %col_names_hash = ();
			for ( my $i = 0; $i < scalar @{$col_names_aref}; $i++ ) {
				$col_names_hash{$col_names_aref->[$i]} = $i;
			}
			
			# go through each column in the matrix making an array
			# of the values passed in by row_vals_aref
			my @arr = ();
			foreach my $col ( @{$self->get_col_names()} ) {
				if ( ! defined $col_names_hash{$col} ) {
					MyX::Table::Col::UndefName->throw(
						error => "Undefined column name: $col",
						name => $col
					);
				}
				
				push @arr, $row_vals_aref->[$col_names_hash{$col}];
			}
			
			# now that I have an array that is ordered by the columns
			# in the matrix I can add it by calling the add_row method
			# again and passing the ordered row_vals_aref.
			# this is kind of a recursive-like short cut :)
			$self->add_row($row_name, \@arr);
		}
		
		return 1;
	}
	
	sub _add_row_checks {
		my ($self, $row_name, $row_vals_aref, $col_names_aref) = @_;
		
		# make sure the parameter values are defined
		_is_defined($row_name, "row_name");
		_is_defined($row_vals_aref, "row_vals_aref");
		
		# make sure the name is not already in the table
		if ( $self->has_row($row_name) ) {
			MyX::Table::Row::NameInTable->throw(
				error => "Name already defined in matrix: $row_name",
				name => $row_name
			);
		}
		
		# make sure the row_vals_aref is an aref
		_is_aref($row_vals_aref, "row_vals_aref");
		
		# if the table is currently empty set the col_count and col_name
		# row_count and row_name values are set in add_row
		if ( $self->get_col_count() == 0 and $self->get_row_count() == 0 ) {
			# if the col_names are not defined thow a parameter undef error
			my $msg = "col_names -- must be defined when add_row is the first row added to a matrix";
			_is_defined($col_names_aref, $msg);
			
			$self->_set_col_count(scalar @{$row_vals_aref});
			$self->_set_col_names($col_names_aref);
		}
		
		# make sure the number of vals in $row_vals_aref is the
		# same as the number of columns in the matrix
		if ( scalar @{$row_vals_aref} != $self->get_col_count() ) {
			MyX::Table::BadDim->throw(
				error => "Number of columns does not equal cols in matrix"
			);
		}
		
		if ( defined $col_names_aref ) {
			# make sure the col_names_aref is an aref
			_is_aref($col_names_aref, "col_names_aref");
			
			# make sure the number of names is the same as the col_count
			if ( scalar @{$col_names_aref} != $self->get_col_count() ) {
				MyX::Table::BadDim->throw(
					error => "Number of column names does not equal cols in matrix"
				);
			}
		}
		
		return 1;
	}
	
	sub add_col {
		my ($self, $col_name, $col_vals_aref, $row_names_aref) = @_;
		
		# NOTE: if col_names_aref is not provided the columns are
		# added in the order provided in the col_vals_aref
		
		# check the parameters
		$self->_add_col_checks($col_name, $col_vals_aref, $row_names_aref);
		
		# add the col in the order provided
		if ( ! defined $row_names_aref ) {
			my $i = 0;
			foreach my $val ( @{$col_vals_aref} ) {
				push @{$mat_of{ident $self}->[$i]}, $val;
				$i++;
			}
			
			# save the name and index (which is the same as the current
			# number of cols) to the col names attribute
			$col_names_of{ident $self}->{$col_name} = $self->get_col_count();
			
			# increment the col count
			$self->_set_col_count($self->get_col_count() + 1);
		}
		else {
			# index the row names for the col that was passed in
			my %row_names_hash = ();
			for ( my $i = 0; $i < scalar @{$row_names_aref}; $i++ ) {
				$row_names_hash{$row_names_aref->[$i]} = $i;
			}
			
			# go through each row in the matrix making an array
			# of the values passed in by col_vals_aref
			my @arr = ();
			foreach my $row ( @{$self->get_row_names()} ) {
				if ( ! defined $row_names_hash{$row} ) {
					MyX::Table::Row::UndefName->throw(
						error => "Undefined row name: $row",
						name => $row
					);
				}
				
				push @arr, $col_vals_aref->[$row_names_hash{$row}];
			}
			
			# now that I have an array that is ordered by the rows
			# in the matrix I can add it by calling the add_col method
			# again and passing the ordered col_vals_aref.
			# this is kind of a recursive-like short cut :)
			$self->add_col($col_name, \@arr);
		}
		
		return 1;
	}
	
	sub _add_col_checks {
		my ($self, $col_name, $col_vals_aref, $row_names_aref) = @_;
		
		# make sure the parameter values are defined
		_is_defined($col_name, "col_name");
		_is_defined($col_vals_aref, "col_vals_aref");
		
		# make sure the name is not already in the table
		if ( $self->has_col($col_name) ) {
			MyX::Table::Col::NameInTable->throw(
				error => "Name already defined in matrix: $col_name",
				name => $col_name
			);
		}
		
		# make sure the row_vals_aref is an aref
		_is_aref($col_vals_aref, "col_vals_aref");
		
		# if the table is currently empty set the row_count and row_name
		# col_count and col_name values are set in add_col
		if ( $self->get_col_count() == 0 and $self->get_row_count() == 0 ) {
			# if the col_names are not defined thow a parameter undef error
			my $msg = "row_names -- must be defined when add_row is the first column added to a matrix";
			_is_defined($row_names_aref, $msg);
			
			$self->_set_row_count(scalar @{$col_vals_aref});
			$self->_set_row_names($row_names_aref);
		}
		
		# make sure the number of vals in $row_vals_aref is the
		# same as the number of columns in the matrix
		if ( scalar @{$col_vals_aref} != $self->get_row_count() ) {
			MyX::Table::BadDim->throw(
				error => "Number of rows does not equal columns in matrix"
			);
		}
		
		if ( defined $row_names_aref ) {
			# make sure the row_names_aref is an aref
			_is_aref($row_names_aref, "row_names_aref");
			
			# make sure the number of names is the same as the col_count
			if ( scalar @{$row_names_aref} != $self->get_row_count() ) {
				MyX::Table::BadDim->throw(
					error => "Number of row names does not equal columns in matrix"
				);
			}
		}
		
		return 1;
	}
	
	sub merge{
		my ($self, $params_href) = @_;
		
		# NOTE: in this function I assume that the columns are in the
		# same order as the column names for both the X and Y (ie passed in)
		# tables.
		
		$params_href = _check_merge_params($params_href);
		
		# make a new table object populate and eventually return
		my $new_tbl = Table::->new();
		
		my @all_row_names = ();
		my @all_col_names = ();
		
		#### Rows
		my @inter_names = ();
		my @uniq_x_names = ();
		my @uniq_y_names = ();
		
		@inter_names = intersect(
			@{$self->get_row_names()},
			@{$params_href->{y_tbl}->get_row_names()}
		);
		
		if ( $params_href->{all_x} ) {
			@uniq_x_names = array_minus(
				@{$self->get_row_names()},
				@{$params_href->{y_tbl}->get_row_names()}
			);
		}
		
		if ( $params_href->{all_y} ) {
			@uniq_y_names = array_minus(
				@{$params_href->{y_tbl}->get_row_names()},
				@{$self->get_row_names()}
			);
		}
		
		@all_row_names = (@inter_names, @uniq_x_names, @uniq_y_names);
		
		#### Cols
		# change any column names that are duplicated in the y_tbl
		# remember that I will have to change these back after I'm
		# done creating the final all_col_names array
		my @uniq_y = intersect(
			@{$self->get_col_names()},
			@{$params_href->{y_tbl}->get_col_names()}
		);
		foreach my $dup_col ( @uniq_y ) {
			$params_href->{y_tbl}->change_col_name($dup_col, $dup_col . "_y");
		}
		
		# now that I may have change some of the column names in y_tbl
		# I should remake the @all_col_names
		@all_col_names = (
			@{$self->get_col_names()},
			@{$params_href->{y_tbl}->get_col_names()}
		);
		
		# change back the names that I changed in the y_tbl object
		foreach my $dup_col ( @uniq_y ) {
			$params_href->{y_tbl}->change_col_name($dup_col . "_y", $dup_col);
		}
		
		# set the col names and counts
		$new_tbl->_set_col_count(scalar @all_col_names);
		$new_tbl->_set_col_names(\@all_col_names);
		
		#### Tbl
		# set the table values
		foreach my $row_name ( @all_row_names ) {
			if ( ! $self->has_row($row_name) ) {
				$new_tbl->add_row(
					$row_name,
					[
						(("NA") x $self->get_col_count()),
						@{$params_href->{y_tbl}->get_row($row_name)}
					]
				);
			}
			elsif ( ! $params_href->{y_tbl}->has_row($row_name) ) {
				$new_tbl->add_row(
					$row_name,
					[
						@{$self->get_row($row_name)},
						(("NA") x $params_href->{y_tbl}->get_col_count())
					]
				);
			}
			else {
				$new_tbl->add_row(
					$row_name,
					[
						@{$self->get_row($row_name)},
						@{$params_href->{y_tbl}->get_row($row_name)}
					]
				);
			}
		}
		
		return($new_tbl);
	}
	
	sub _check_merge_params {
		my ($params_href) = @_;
		
		# check the second table 
		_is_defined($params_href->{y_tbl}, "y_tbl");
		
		if ( ref $params_href->{y_tbl} ne "Table" ) {
			MyX::Generic::Ref::UnsupportedType->throw(
				error => "y_tbl must be of type Table"
			);
		}
		
		# check all_x
		if ( ! defined $params_href->{all_x} ) {
			$params_href->{all_x} = 0;
		}
		else {
			$params_href->{all_x} = _to_bool($params_href->{all_x});
		}
		
		# check all_y
		if ( ! defined $params_href->{all_y} ) {
			$params_href->{all_y} = 0;
		}
		else {
			$params_href->{all_y} = _to_bool($params_href->{all_y});
		}
		
		return($params_href);
	}
	
	sub has_row {
		my ($self, $row) = @_;
		
		_is_defined($row);
		
		if ( defined $row_names_of{ident $self}->{$row} ) {
			return 1;  # TRUE
		}
		else {
			return 0; # FALSE
		}
	}
	
	sub has_col {
		my ($self, $col) = @_;
		
		_is_defined($col);
		
		if ( defined $col_names_of{ident $self}->{$col} ) {
			return 1;  # TRUE
		}
		else {
			return 0; # FALSE
		}
	}
	
	sub _aref_to_href {
		my ($aref) = @_;
		
		# this method transforms an array reference to a hash reference
		# with {value} => {index}
		my %hash = ();
		
		my $i = 0;
		foreach my $val ( @{$aref} ) {
			$hash{$val} = $i;
			$i++;
		}
		
		return(\%hash);
	}
	
	sub _check_file {
		my ($file) = @_;
		
		# check if the file parameter is defined
		_is_defined($file, "file");
		
		# check if the file exists
		if ( ! -f $file ) {
			MyX::Generic::DoesNotExist::File->throw(
				error => "File ($file) does not exist"
			)
		}
		
		# check that the file is non empty
		if ( ! -s $file ) {
			MyX::Generic::File::Empty->throw(
				error => "File ($file) is empty"
			);
		}
		
		return 1;
	}
	
	sub _set_sep {
		my ($sep) = @_;
		
		if ( ! defined $sep ) {
			return($SEP);
		}
		
		return($sep);
	}
	
	sub _check_row_name {
		my ($self, $row) = @_;
		
		# check if the row parameter is defined
		_is_defined($row, "row");
		
		# check if the row exists in the table
		my $row_href = $row_names_of{ident $self};
		if ( ! defined $row_href->{$row} ) {
			MyX::Table::Row::UndefName->throw(
				error => "Undefined row name: $row",
				name => $row
			);
		}
		
		return 1;
	}
	
	sub _check_col_name {
		my ($self, $col) = @_;
		
		# check if the col parameter is defined
		if ( ! defined $col ) {
			MyX::Generic::Undef::Param->throw(
				error => "Undefined parameter value (col)"
			);
		}
		
		# check if the col exists in the table
		my $col_href = $col_names_of{ident $self};
		if ( ! defined $col_href->{$col} ) {
			MyX::Table::Col::UndefName->throw(
				error => "Undefined col name: $col",
				name => $col
			);
		}
		
		return 1;
	}
	
	sub _is_defined {
		my ($val, $val_name) = @_;
		
		if ( ! defined $val ) {
			MyX::Generic::Undef::Param->throw(
				error => "Undefined parameter value ($val_name)"
			);
		}
		
		return 1;
	}
	
	sub _is_aref {
		my ($aref, $name) = @_;
		
		if ( ref($aref) ne "ARRAY" ) {
			MyX::Generic::Ref::UnsupportedType->throw(
				error => "$name must be an array reference"
			);
		}
		
		return 1;
	}
	
	sub _to_bool {
        my ($val) = @_;
     
        if ( $val eq 1 or $val eq 0 ) {
            return $val;
        }    
     
        my %good_yes_values = map { $_ => 1 } qw(Y YES Yes y yes T t TRUE true True);
        if ( defined $good_yes_values{$val} ) {
            return 1;
        }    
     
        # else -- meaning FALSE
        return 0;
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
	$table->load("my_table.txt", "\t");
	
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
	# TO DO
  
  
=head1 DESCRIPTION

This module is an object for storing and opperating on tables (ie 2D matrix).


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
	sub get_row;
	sub get_col;
	sub get_row_index;
	sub get_col_index;

	# Setters #
	sub _set_row_count;
	sub _set_col_count;
	sub _set_row_names;
	sub _set_col_names;

	# Others #
	sub load_from_file;
	sub load_from_href_href; # to do
	sub save;
	sub to_str;
	sub add_row;
	sub _add_row_checks;
	sub add_col;
	sub _add_col_checks;
	sub merge; # to do
	sub transpose; # to do
	sub reset; # to do
	sub _aref_to_href;
	sub _check_file;
	sub _set_sep;
	sub _check_row_name;
	sub _check_col_name;
	sub _is_defined;

=back

=head1 METHODS DESCRIPTION

=head2 new

	Title: new
	Usage: Table->new({
				arg1 => $arg1,
				arg2 => $arg2
			});
	Function:
	Returns: Table
	Args: -arg1 => DESCRIPTION
		  -arg2 => DESCRIPTION
	Throws: MyX::Generic::Undef::Params
	Comments: NA
	See Also: NA
	
=head2 get_arg1

	Title: get_arg1
	Usage: $obj->get_arg1()
	Function: Returns arg1
	Returns: str
	Args: NA
	Throws: NA
	Comments: NA
	See Also: NA
	
=head2 set_arg1

	Title: set_arg1
	Usage: $obj->set_arg1($arg1)
	Function: sets the arg1 value
	Returns: 1 on success
	Args: -arg1 => DESCRIPTION
	Throws: MyX::Generic::Undef::Param
	Comments: NA
	See Also: NA


=head1 BUGS AND LIMITATIONS

=for author to fill in:
    A list of known problems with the module, together with some
    indication Whether they are likely to be fixed in an upcoming
    release. Also a list of restrictions on the features the module
    does provide: data types that cannot be handled, performance issues
    and the circumstances in which they may arise, practical
    limitations on the size of data sets, special cases that are not
    (yet) handled, etc.

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-table@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 TO DO

=head2 check for columns without correct number

When I read in the table there could be columns that are not square
with the rest of columns.

=head2 add to a repository

add to source forge

=head2 finish documentaiton

ugh, boring, but super important.

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


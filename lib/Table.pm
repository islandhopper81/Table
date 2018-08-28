package Table;

use MyX::Table;
use Table::Iter;
use MyX::Table::Iter;

use warnings;
use strict;
use Carp;
use Readonly;
use Class::Std::Utils;
use Array::Utils qw(:all);
use Scalar::Util qw(looks_like_number);
use List::MoreUtils qw(any);
use Log::Log4perl qw(:easy);
use List::Compare;
use MyX::Generic;
use version; our $VERSION = qv('0.0.2');
use UtilSY qw(aref_to_href href_to_aref check_ref to_bool aref_to_str);

# set up the logging environment
my $logger = get_logger();

{
	# Usage statement
	Readonly my $NEW_USAGE => q{ new()};
	Readonly::Scalar my $SEP => "\t";
    Readonly::Scalar my $COMM_CHAR => undef;
    Readonly::Scalar my $SKIP_AFTER => undef;
    Readonly::Scalar my $SKIP_BEFORE => undef;

	# Attributes #
	my %row_count_of;
	my %col_count_of;
	my %row_names_of; # a href
	my %col_names_of; # a href
	my %row_names_order_of; # a href
	my %col_names_order_of; # a href
	my %mat_of;
	my %row_names_header_of; 
	
	# Getters #
	sub get_row_count;
	sub get_col_count;
	sub get_row_names;
	sub get_col_names;
	sub get_col_headers;
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
	sub order_rows;
	sub order_cols;
	sub sort_by_col;
	sub rekey_row_names;
	sub rekey_col_headers;
	sub save;
	sub to_str;
	sub change_row_name;
	sub change_col_name;
	sub add_row;
	sub _add_row_checks;
	sub add_col;
	sub _add_col_checks;
	sub drop_row;
	sub _drop_row_checks;
	sub drop_col;
	sub _drop_col_checks;
	sub _decrement_name_indicies;
	sub subset;
	sub merge;
	sub _check_merge_params;
	sub cbind;
	sub rbind;
	sub transpose;
	sub reset;
	sub copy;
	sub has_row;
	sub has_col;
	sub has_row_names_header;
	sub is_empty;
	sub _load_case_1;
	sub _load_case_2;
	sub _load_case_3;
	sub _load_case_4_or_5;
    sub _is_comment;
    sub _is_skip_after;
    sub _is_skip_before;
    sub _is_whitespace;
	sub _set_default_col_headers;
	sub _check_header_format;
	sub _count_end_seps;
	sub _aref_to_href;
	sub _check_file;
	sub _set_sep;
    sub _set_comm_char;
    sub _set_skip_after;
    sub _set_skip_before;
	sub _has_col_headers;
	sub _has_row_names;
	sub _check_row_name;
	sub _check_col_name;
	sub _is_aref;
	sub _check_defined;
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

		# Bless a scalar to instantiate an object
		my $new_obj = bless \do{my $anon_scalar}, $class;

		# Set Attributes
		$new_obj->_set_col_count(0);
		$new_obj->_set_row_count(0);
		$new_obj->_set_row_names_header();
		
		# I added these lines because they solved a problem I was having when
		# trying to make a copy of self in the transpose method.  Note that I
		# can't simply call _set_col_names(undef) or _set_row_names(undef)
		# because those methods call _check_defined to make sure I'm setting the
		# rows or columns to something that is defined.
		$col_names_of{ident $new_obj} = undef;
		$row_names_of{ident $new_obj} = undef;
		
		# I added these attributes so that I could easily reorder the col or
		# rows in a memrory efficient manner
		$col_names_order_of{ident $new_obj} = undef;
		$row_names_order_of{ident $new_obj} = undef;
		
		# I added this to help again with the copy subroutine
		$mat_of{ident $new_obj} = undef;

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
		my ($self, $by_index) = @_;
		
		# set the default for by_index
		if ( ! _is_defined($by_index) ) {
			$by_index = 0; # FALSE
		}
		
		my @arr = ();
		
		if ( _to_bool($by_index) ) {
			# returns the names in an array ref ordered by their table index
			my $names_href = $row_names_of{ident $self};
			@arr = sort { $names_href->{$a} <=> $names_href->{$b} } keys(%$names_href);
		}
		else {
			# returns the names in an array ref ordered by their defined order
			my $names_href = $row_names_order_of{ident $self};
			@arr = sort { $names_href->{$a} <=> $names_href->{$b} } keys(%$names_href);
		}
		
		return(\@arr);
	}
	
	sub get_col_names {
		my ($self, $by_index) = @_;
		
		# set the default for by_index
		if ( ! _is_defined($by_index) ) {
			$by_index = 0; # FALSE
		}
		
		my @arr = ();
		
		if ( _to_bool($by_index) ) {
			# returns the names in an array ref ordered by their table index
			my $names_href = $col_names_of{ident $self};
			@arr = sort { $names_href->{$a} <=> $names_href->{$b} } keys(%$names_href);
		}
		else {
			# returns the names in an array ref ordered by their defined order
			my $names_href = $col_names_order_of{ident $self};
			@arr = sort { $names_href->{$a} <=> $names_href->{$b} } keys(%$names_href);
		}
		
		return(\@arr);
	}
	
	sub get_col_headers {
		my ($self, $by_index) = @_;
		
		# an alternate name for get_col_names() function
		
		return($self->get_col_names($by_index));
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
	
	sub get_value_at_fast {
		my ($self, $r, $c) = @_;
		
		# WARNING: It is not advised to call this method directly.  In other
		# wards treat it as a private method.  See documentation for more
		# details
		
		return($mat_of{ident $self}->[$r][$c]);
	}
	
	sub get_row {
		my ($self, $row) = @_;
		
		$self->_check_row_name($row);
		my $r = $self->get_row_index($row);
		
		my $aref = $mat_of{ident $self}->[$r];
		
		# now make sure the values ie columns for this row are correctly ordered
		my @order = ();
		foreach my $c ( @{$self->get_col_names()} ) {
			push @order, $self->get_col_index($c);
		}
		my @ordered = ();
		@ordered[@order] = @{$mat_of{ident $self}->[$r]};
		
		#return($mat_of{ident $self}->[$r]);
		return(\@ordered);
	}
	
	sub get_col {
		my ($self, $col) = @_;
		
		# NOTE: this is the slow one
		
		$self->_check_col_name($col);
		my $c = $self->get_col_index($col);
		
		my @col_arr = ();
		my $i = 0;

		foreach my $row_aref ( @{$mat_of{ident $self}} ) {
			$i++;
			push @col_arr, $row_aref->[$c];
		}
		
		# at this point the col is ordered as it is in the matrix.  I need to
		# reorder it according to the ordering of the names
		my @order = ();
		foreach my $r ( @{$self->get_row_names()} ) {
			push @order, $self->get_row_index($r);
		}
		@col_arr[@order] = @col_arr;
		
		return(\@col_arr);
	}
	
	sub get_row_index {
		my ($self, $row) = @_;
		
		$self->_check_row_name($row);
		my $r = $row_names_of{ident $self}->{$row};
		
		return($r);
	}
	
	sub get_col_index {
		my ($self, $col) = @_;
		
		$self->_check_col_name($col);
		my $c = $col_names_of{ident $self}->{$col};
		
		return($c);
	}
	
	sub get_row_names_header {
		my ($self) = @_;
		
		return $row_names_header_of{ident $self};
	}

	###########
	# Setters #
	###########
	sub change_row_name {
		my ($self, $current, $new) = @_;
		
		_check_defined($current, "current name");
		_check_defined($new, "new name");
		
		# check if the current name is in the table
		if ( ! $self->has_row($current) ) {
			MyX::Table::Col::UndefName->throw(
				error => "No such row name: $current\n"
			);
		}
		
		my $index = $row_names_of{ident $self}->{$current};
		$row_names_of{ident $self}->{$new} = $index;
		delete $row_names_of{ident $self}->{$current};
		
		my $pos = $row_names_order_of{ident $self}->{$current};
		$row_names_order_of{ident $self}->{$new} = $pos;
		delete $row_names_order_of{ident $self}->{$current};
		
		return 1;
	}
	
	sub change_col_name {
		my ($self, $current, $new) = @_;
		
		_check_defined($current, "current name");
		_check_defined($new, "new name");
		
		# check if the current name is in the table
		if ( ! $self->has_col($current) ) {
			MyX::Table::Col::UndefName->throw(
				error => "No such column name: $current\n"
			);
		}
		
		my $index = $col_names_of{ident $self}->{$current};
		$col_names_of{ident $self}->{$new} = $index;
		delete $col_names_of{ident $self}->{$current};
		
		my $pos = $col_names_order_of{ident $self}->{$current};
		$col_names_order_of{ident $self}->{$new} = $pos;
		delete $col_names_order_of{ident $self}->{$current};
		
		return 1;
	}

	sub set_value_at {
        my ($self, $row, $col, $val) = @_;
     
        # this function will likely be slow is you use it iteratively
		# so don't load a whole table using this function; it doesn't
		# make sense to do that (trust me).
     
        $self->_check_row_name($row);
        $self->_check_col_name($col);
     
        my $r = $self->get_row_index($row);
        my $c = $self->get_col_index($col);
     
        $mat_of{ident $self}->[$r][$c] = $val;

		return 1;
	}
	
	sub _set_row_count {
		my ($self, $row_count) = @_;
		
		# check if the parameter is defined
		_check_defined($row_count, "row_count");

		# check if row_count is a number
		if ( ! looks_like_number($row_count) ) {
			MyX::Generic::Digit::MustBeDigit->throw(
				error => "row_count parameter must be a digit > 0\n"
			);
		}
		
		# make sure the number is >= 0
		if ( $row_count < 0 ) {
			MyX::Generic::Digit::TooSmall->throw(
				error => "row_count parameter must be a digit > 0\n"
			);
		}
		
		$row_count_of{ident $self} = $row_count;
		
		return 1;
	}
	
	sub _set_col_count {
		my ($self, $col_count) = @_;
		
		# check if the parameter is defined
		_check_defined($col_count, "col_count");
		
		# check if col_count is a number
		if ( ! looks_like_number($col_count) ) {
			MyX::Generic::Digit::MustBeDigit->throw(
				error => "col_count parameter must be a digit > 0\n"
			);
		}
		
		# make sure the number is >= 0
		if ( $col_count < 0 ) {
			MyX::Generic::Digit::TooSmall->throw(
				error => "col_count parameter must be a digit > 0\n"
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
		_check_defined($row_names_aref, "row_names_aref");
		
		# check rule 1
		if ( $self->get_row_count() != scalar @{$row_names_aref} ) {
			MyX::Table::BadDim->throw(
				error => "Col count and number of row names does NOT match\n",
				dim => "Col"
			);
		}
		
		# check rule 2
		my $row_names_href = _aref_to_href($row_names_aref);
		my $row_names_order_href = _aref_to_href($row_names_aref);
		if ( $self->get_row_count() != scalar(keys %{$row_names_href}) ) {
			MyX::Table::NamesNotUniq->throw(
				error => "Col names not unique\n",
				dim => "Col"
			);
		}
		
		$row_names_of{ident $self} = $row_names_href;
		$row_names_order_of{ident $self} = $row_names_order_href;
		
		return 1;
	}
	
	sub _set_col_names {
		my ($self, $col_names_aref) = @_;
		
		# Rules: 
		# 1. the number of col names must match the number of cols
		# 2. the col names must be unique (ie no repeats)
		
		# check if the parameter is defined
		_check_defined($col_names_aref, "col_names_aref");
		
		# check rule 1
		if ( $self->get_col_count() != scalar @{$col_names_aref} ) {
			MyX::Table::BadDim->throw(
				error => "Col count and number of col names does NOT match\n",
				dim => "Col"
			);
		}
		
		# check rule 2
		my $col_names_href = _aref_to_href($col_names_aref);
		my $col_names_order_href = _aref_to_href($col_names_aref);
		if ( $self->get_col_count() != scalar(keys %{$col_names_href}) ) {
			MyX::Table::NamesNotUniq->throw(
				error => "Col names not unique\n",
				dim => "Col"
			);
		}
		
		$col_names_of{ident $self} = $col_names_href;
		$col_names_order_of{ident $self} = $col_names_order_href;
		
		return 1;
	}
	
	sub _set_col_headers {
		my ($self, $col_names_aref) = @_;
		
		# a wrapper for an alternate name to _set_col_names
		
		return($self->_set_col_names($col_names_aref));
	}
	
	sub _set_row_names_header {
		my ($self, $row_names_header) = @_;
		
		$row_names_header_of{ident $self} = $row_names_header;
	}
	
	##########
	# Others #
	##########
	sub load_from_href_href {
		my ($self, $href, $row_names_aref, $col_names_aref) = @_;
		
		# NOTE: I assume the first level in the href is rows
		
		_check_defined($href, "href");
		_check_defined($row_names_aref, "row names");
		_check_defined($col_names_aref, "col names");
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
		my ($self, $file, $sep, $has_col_header, $has_row_names) = @_;

        my ($comm_char, $skip_after, $skip_before);
		
		# I'm updated the parameter to use a hash ref. This reduces the chance
		# of misordering the parameters.  Using a hash ref to pass the
		# parameters is the recommended usage.
		if ( ref($file) eq "HASH" ) {
			my $args_href = $file;
			my %file_args = map {$_ => 1 } qw(FILE F file f);
			my %sep_args = map {$_ => 1 } qw(SEP S sep s );
			my %hch_args = map {$_ => 1 } qw(has_col_header has_col_headers );
			my %hrn_args = map {$_ => 1 } qw(has_row_names has_row_name );
            my %comm_char_args = map {$_ => 1 } qw(comm_char);
            my %skip_after_args = map {$_ => 1 } qw(skip_after);
            my %skip_before_args = map {$_ => 1 } qw(skip_before);
			
			foreach my $file_arg ( keys %file_args ) {
				if ( defined $args_href->{$file_arg} ) {
					$file = $args_href->{$file_arg};
				}
			}
			
			foreach my $sep_arg ( keys %sep_args ) {
				if ( defined $args_href->{$sep_arg} ) {
					$sep = $args_href->{$sep_arg};
				}
			}
			
			foreach my $hch_arg ( keys %hch_args ) {
				if ( defined $args_href->{$hch_arg} ) {
					$has_col_header = $args_href->{$hch_arg};
				}
			}
			
			foreach my $hrn_arg ( keys %hrn_args ) {
				if ( defined $args_href->{$hrn_arg} ) {
					$has_row_names = $args_href->{$hrn_arg};
				}
			}

            foreach my $comm_char_arg ( keys %comm_char_args ) {
                if ( defined $args_href->{$comm_char_arg} ) {
                    $comm_char = $args_href->{$comm_char_arg};
                }
            }

            foreach my $skip_after_arg ( keys %skip_after_args ) {
                if ( defined $args_href->{$skip_after_arg} ) {
                    $skip_after = $args_href->{$skip_after_arg};
                }
            }
            
            foreach my $skip_before_arg ( keys %skip_before_args ) {
                if ( defined $args_href->{$skip_before_arg} ) {
                    $skip_before = $args_href->{$skip_before_arg};
                }
            }
		}
		
		_check_file($file);
		
		# set the seperator (ie delimitor)
		$sep = _set_sep($sep);

        # set the comment character
        $comm_char = _set_comm_char($comm_char);

        # set the skip after line number
        $skip_after = _set_skip_after($skip_after);

        # set the skip before line number
        $skip_before = _set_skip_before($skip_before);
		
		open my $IN, "<", $file or
			MyX::Generic::File::CannotOpen->throw(
				error => "Cannot read file\n",
				file_name => $file
			);
		
		# set the default values for has_col_header and has_row_header
		$has_col_header = _has_col_headers($has_col_header);
		$has_row_names = _has_row_names($has_row_names);
		
		# figure out the format of the headers.  There are several cases:
		# 1. no column headers, no row names
		# 2. no column headers, has row names
		# 3. has column headers, no row names
		# 4. has column headers no header for row names, has row names
		# 5. has column headers with header for row names, has row names (default)
		
		# Case 1: has_col_header == F AND has_row_names == F
		if ( $has_col_header == 0 and $has_row_names == 0 ) {
			$self->_load_case_1($IN, $sep, $comm_char, $skip_after, $skip_before);
		}
		
		# Case 2: has_col_header == F AND has_row_names == T
		elsif ( $has_col_header == 0 and $has_row_names == 1 ) {
			$self->_load_case_2($IN, $sep, $comm_char, $skip_after, $skip_before);
		}
		
		# Case 3: has_col_header == T AND has_row_names == F
		elsif ( $has_col_header == 1 and $has_row_names == 0 ) {
			$self->_load_case_3($IN, $sep, $comm_char, $skip_after, $skip_before);
		}
		
		# Case 4: has_col_header == T AND has_row_names == T (check for row header)
		# Case 5: has_col_header == T AND has_row_names == T (check for row header)
		elsif ( $has_col_header == 1 and $has_row_names == 1 ) {
			# this handles cases 4 and 5 because they are very similar
			$self->_load_case_4_or_5($IN, $sep, $comm_char, $skip_after, $skip_before);
		}
		
		else {
			my $msg = "Something went terribly wrong with the ";
			$msg .= "has_col_headers or has_row_names parameters";
			
			MyX::Generic->throw(
				error => $msg
			);
		}
		
		return 1;
	}
	
	sub order_rows {
		my ($self, $row_names_aref) = @_;
		
		# make sure $row_names_aref is defined
		_check_defined($row_names_aref, "row_names_aref");
		
		# make sure $row_names_aref is an array reference
		_is_aref($row_names_aref, "row_names_aref");
		
		# make sure all the given row names are in the table row names are equal
		my $lc = List::Compare->new($row_names_aref, $self->get_row_names());
		if ( ! $lc->is_LequivalentR() ) {
			# throw an error
			MyX::Table::Order::Row::NamesNotEquiv->throw(
				error => "Row names are not equivalent\n",
			);
		}
		
		# updated the row_names_order_of attribute
		my $i = 0;
		foreach my $name ( @{$row_names_aref} ) {
			$row_names_order_of{ident $self}->{$name} = $i;
			$i++;
		}
		
		return(1);
	}
	
	sub order_cols {
		my ($self, $col_names_aref) = @_;
		
		# make sure $col_names_aref is defined
		_check_defined($col_names_aref, "col_names_aref");
		
		# make sure $row_names_aref is an array reference
		_is_aref($col_names_aref, "col_names_aref");
		
		# make sure all the given col names are in the table col names are equal
		my $lc = List::Compare->new($col_names_aref, $self->get_col_names());
		if ( ! $lc->is_LequivalentR() ) {
			# throw an error
			MyX::Table::Order::Col::NamesNotEquiv->throw(
				error => "Col names are not equivalent\n",
			);
		}
		
		# updated the row_names_order_of attribute
		my $i = 0;
		foreach my $name ( @{$col_names_aref} ) {
			$col_names_order_of{ident $self}->{$name} = $i;
			$i++;
		}
		
		return(1);
	}
	
	sub sort_by_col {
		my ($self, $col_name, $numeric, $decending) = @_;
		
		# sorts by the values in a given column
		
		# TO DO
		# 1. change the way the params are passed.  Use a hash.  Currently if
		#	 you want to use either numeric or decending you must use both
		
		# col_name checks
		_check_defined($col_name, "col_name");
		if ( ! $self->has_col($col_name) ) {
			MyX::Table::Col::UndefName->throw(
				error => "Col ($col_name) is not in Table\n",
				name => $col_name
			);
		}
		
		# check numeric
		if ( ! _is_defined($numeric) ) {
			$numeric = 0; # FALSE
		}
		else {
			$numeric = _to_bool($numeric);
		}
		
		# check decending
		if ( ! _is_defined($decending) ) {
			$decending = 0; # FALSE
		}
		
		# get the row order by sorting the given col
		# NOTE: there is probably a faster way to create the unsorted hash
		my %unsorted = ();
		foreach my $r ( @{$self->get_row_names()} ) {
			$unsorted{$r} = $self->get_value_at($r, $col_name);
		}
		
		# get the list of sorted names
		my @sorted_names = ();
		if ( $numeric ) {
			@sorted_names = sort { $unsorted{$b} <=> $unsorted{$a} } keys %unsorted;
		}
		else {
			@sorted_names = sort { $unsorted{$b} cmp $unsorted{$a} } keys %unsorted;
		}

		# reverse the array if it should be in decreasing order		
		if ( ! _to_bool($decending) ) {
			@sorted_names = reverse @sorted_names;
		}
		
		# updated the row_names_order_of attribute
		$self->order_rows(\@sorted_names);
		#my $i = 0;
		#foreach my $name ( @sorted_names ) {
		#	$row_names_order_of{ident $self}->{$name} = $i;
		#	$i++;
		#}
		
		return (1);
	}
	
	sub rekey_row_names {
		my ($self, $col_name, $new_col_header) = @_;
		
		# given a column, use this column as the new row names

		# set the row_names_header. needed to name the old column of row names
		if ( ! _is_defined($new_col_header) ) {
			if ( $self->has_row_names_header() ) {
				$new_col_header = $self->get_row_names_header();
			}
			else {
				$new_col_header = "old_row_names";
			}
		}
		
		# check the column to make sure the values are uniq
		my $new_row_names = $self->get_col($col_name);
		my $row_names_href = _aref_to_href($new_row_names);
		if ( $self->get_row_count() != scalar(keys %{$row_names_href}) ) {
			MyX::Table::NamesNotUniq->throw(
				error => "Cannot rekey because values in $col_name not uniq\n",
				dim => "Col"
			);
		}
		
		# set the old row names as a new column
		my $old_row_names = $self->get_row_names();
		$self->add_col($new_col_header, $old_row_names);
		
		# set the given column as the new row names
		$self->_set_row_names($new_row_names);
		
		# set the row names header. If the current row names header is
		# old_row_names I am setting the row_names_header to ""
		if ( $col_name =~ m/old_row_names/ ) {
			$self->_set_row_names_header("");
		}
		else {
			$self->_set_row_names_header($col_name);
		}
		
		# remove the given column that are now the row names
		$self->drop_col($col_name);
		
		return 1;
	}
	
	sub rekey_col_headers {
		my ($self, $row_name, $new_row_name) = @_;
		
		# given a column, use this column as the new row names

		# the new_row_name is required because the column headers are not
		# named like the row names are.
		_check_defined($new_row_name, "new_row_name");
		
		# check the row to make sure the values are uniq
		my $new_col_headers = $self->get_row($row_name);
		my $col_headers_href = _aref_to_href($new_col_headers);
		if ( $self->get_col_count() != scalar(keys %{$col_headers_href}) ) {
			MyX::Table::NamesNotUniq->throw(
				error => "Cannot rekey because values in $row_name not uniq\n",
				dim => "Row"
			);
		}
		
		# set the old col headers as a new row
		my $old_col_headers = $self->get_col_headers();
		$self->add_row($new_row_name, $old_col_headers);
		
		# set the given row as the new col headers
		$self->_set_col_headers($new_col_headers);
		
		# note that row_name will be lost
		
		# remove the given column that are now the row names
		$self->drop_row($row_name);
		
		return 1;
	}
	
	sub save {
		my ($self, $file, $sep, $print_col_header, $print_row_names) = @_;
		
		# NOTE: I assume that the matrix is already in order
		# 		ie the names index match the order in the 2d array
		
		my $args_href = undef;
		if ( ref($file) eq "HASH" ) {
			$args_href = $file;
			my %file_vals = map {$_ => 1 } qw(FILE F file f );
			
			foreach my $file_val ( keys %file_vals ) {
				if ( defined $args_href->{$file_val} ) {
					$file = $args_href->{$file_val};
				}
			}
		}
		# check if the file parameter is defined
		_check_defined($file, "file");
		
		open my $OUT, ">", $file or
			MyX::Generic::File::CannotOpen->throw(
				error => "Cannot open file ($file) for writing\n"
			);
			
		my $str;
		if ( defined $args_href ) {
			$str = $self->to_str($args_href);
		}
		else {
			$str = $self->to_str($sep, $print_col_header, $print_row_names);
		}
		
		print $OUT $str;
		
		return 1;
	}
	
	sub to_str {
		my ($self, $sep, $print_col_header, $print_row_names) = @_;
		
		# I'm updated the parameter to use a hash ref. This reduces the chance
		# of misordering the parameters.  Using a hash ref to pass the
		# parameters is the recommended usage.
		if ( ref($sep) eq "HASH" ) {
			my $args_href = $sep;
			$sep = undef;
			my %sep_vals = map {$_ => 1 } qw(SEP S sep s );
			my %pch_vals = map {$_ => 1 } qw(print_col_header print_col_headers );
			my %prn_vals = map {$_ => 1 } qw(print_row_names print_row_name );

			foreach my $sep_val ( keys %sep_vals ) {
				if ( defined $args_href->{$sep_val} ) {
					$sep = $args_href->{$sep_val};
				}
			}
			
			foreach my $pch_val ( keys %pch_vals ) {
				if ( defined $args_href->{$pch_val} ) {
					$print_col_header = $args_href->{$pch_val};
				}
			}
			
			foreach my $prn_val ( keys %prn_vals ) {
				if ( defined $args_href->{$prn_val} ) {
					$print_row_names = $args_href->{$prn_val};
				}
			}
		}
		
		# if the table is empty return an empty string
		if ( $self->is_empty() ) {
			return "";
		}
		
		# set the seperator (ie delimitor)
		$sep = _set_sep($sep);
		
		# set the default values for has_col_header and has_row_header
		$print_col_header = _has_col_headers($print_col_header);
		$print_row_names = _has_row_names($print_row_names);
		
		my $str = "";
		
		if ( $print_col_header == 1 ) {
			# check if a row names header is present
			if ( $self->has_row_names_header() ) {
				$str .= $self->get_row_names_header() . $sep;
			}
			
			# print the column headers
			$str .= (join($sep, @{$self->get_col_names()}));
			$str .= "\n";
		}
		
		# print the row names and each row in the matrix
		my $row_count = $self->get_row_count();
		my $row_names_aref = $self->get_row_names();
		my @row_vals = ();  # for reordering the values
		foreach my $row ( @{$row_names_aref} ) {
			if ( $print_row_names == 1 ) {
				$str .= $row . $sep;
			}
			$str .= (join($sep, @{$self->get_row($row)}));
			$str .= "\n";
		}
		
		return($str);
	}
	
	sub add_row {
		my ($self, $row_name, $row_vals_aref, $col_names_aref) = @_;
		
		# NOTE: if col_names_aref is not provided the rows are
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
			$row_names_order_of{ident $self}->{$row_name} = $self->get_row_count();
			
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
			my $by_index = 1; # TRUE
			foreach my $col ( @{$self->get_col_names($by_index)} ) {
				if ( ! defined $col_names_hash{$col} ) {
					MyX::Table::Col::UndefName->throw(
						error => "Undefined column name: $col\n",
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
		_check_defined($row_name, "row_name");
		_check_defined($row_vals_aref, "row_vals_aref");
		
		# make sure the name is not already in the table
		if ( $self->has_row($row_name) ) {
			MyX::Table::Row::NameInTable->throw(
				error => "Name already defined in matrix: $row_name\n",
				name => $row_name
			);
		}
		
		# make sure the row_vals_aref is an aref
		_is_aref($row_vals_aref, "row_vals_aref");
		
		# if the table is currently empty set the col_count and col_name
		# row_count and row_name values are set in add_row
		if ( $self->get_col_count() == 0 and $self->get_row_count() == 0 ) {
			# if the col_names are not defined throw a parameter undef error
			my $msg = "col_names -- must be defined when add_row is the first row added to a matrix";
			_check_defined($col_names_aref, $msg);
			
			$self->_set_col_count(scalar @{$row_vals_aref});
			$self->_set_col_names($col_names_aref);
		}
		
		# make sure the number of vals in $row_vals_aref is the
		# same as the number of columns in the matrix
		if ( scalar @{$row_vals_aref} != $self->get_col_count() ) {
			MyX::Table::BadDim->throw(
				error => "Number of columns does not equal cols in matrix\n"
			);
		}
		
		if ( defined $col_names_aref ) {
			# make sure the col_names_aref is an aref
			_is_aref($col_names_aref, "col_names_aref");
			
			# make sure the number of names is the same as the col_count
			if ( scalar @{$col_names_aref} != $self->get_col_count() ) {
				MyX::Table::BadDim->throw(
					error => "Number of column names does not equal cols in matrix\n"
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
			$col_names_order_of{ident $self}->{$col_name} = $self->get_col_count();
			
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
			my $by_index = 1;  # TRUE
			foreach my $row ( @{$self->get_row_names($by_index)} ) {
				if ( ! defined $row_names_hash{$row} ) {
					MyX::Table::Row::UndefName->throw(
						error => "Undefined row name: $row\n",
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
		_check_defined($col_name, "col_name");
		_check_defined($col_vals_aref, "col_vals_aref");
		
		# make sure the name is not already in the table
		if ( $self->has_col($col_name) ) {
			MyX::Table::Col::NameInTable->throw(
				error => "Name already defined in matrix: $col_name\n",
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
			_check_defined($row_names_aref, $msg);
			
			$self->_set_row_count(scalar @{$col_vals_aref});
			$self->_set_row_names($row_names_aref);
		}
		
		# make sure the number of vals in $row_vals_aref is the
		# same as the number of columns in the matrix
		if ( scalar @{$col_vals_aref} != $self->get_row_count() ) {
			MyX::Table::BadDim->throw(
				error => "Number of rows does not equal columns in matrix\n"
			);
		}
		
		if ( defined $row_names_aref ) {
			# make sure the row_names_aref is an aref
			_is_aref($row_names_aref, "row_names_aref");
			
			# make sure the number of names is the same as the col_count
			if ( scalar @{$row_names_aref} != $self->get_row_count() ) {
				MyX::Table::BadDim->throw(
					error => "Number of row names does not equal columns in matrix\n"
				);
			}
		}
		
		return 1;
	}
	
	sub drop_row {
		my ($self, $row_name) = @_;
		
		$self->_drop_row_checks($row_name);
		
		# get the index of the row
		my $row_i = $self->get_row_index($row_name);
		
		splice @{$mat_of{ident $self}}, $row_i, 1;
		
		# subtract one from row count
		$self->_set_row_count($self->get_row_count() - 1);
		
		# adjust the indicies in the row_names_of attribute
		my $row_names_of_href = $row_names_of{ident $self};
		_decrement_name_indicies($row_names_of_href, $row_i);
		my $row_names_order_of_href = $row_names_order_of{ident $self};
		_decrement_name_indicies($row_names_order_of_href, $row_i);
		
		# remove the key fromt he row_nams_of href
		delete $row_names_of_href->{$row_name};
		delete $row_names_order_of_href->{$row_name};
		
		# if there are no more rows then reset the table
		if ( $self->is_empty() ) {
			$self->reset();
		}
		
		return 1;
	}
	
	sub _drop_row_checks {
		my ($self, $row_name) = @_;
		
		# make sure the parameter values are defined
		_check_defined($row_name, "row_name");
		
		# ensure the row is actually in the table
		if ( ! $self->has_row($row_name) ) {
			MyX::Table::Row::UndefName->throw(
				error => "Row ($row_name) is not in Table\n",
				name => $row_name
			);
		}
		
		return 1;
	}
	
	sub drop_col {
		my ($self, $col_name) = @_;
		
		$self->_drop_col_checks($col_name);
		
		# get the index of the col
		my $col_i = $self->get_col_index($col_name);
		
		for ( my $i = 0; $i < $self->get_row_count(); $i++ ) {
			splice(@{$mat_of{ident $self}->[$i]}, $col_i, 1);
		}
		
		# subtract one from row count
		$self->_set_col_count($self->get_col_count - 1);
		
		# adjust the indicies in the col_names_of attribute
		my $col_names_of_href = $col_names_of{ident $self};
		_decrement_name_indicies($col_names_of_href, $col_i);
		my $col_names_order_of_href = $col_names_order_of{ident $self};
		_decrement_name_indicies($col_names_order_of_href, $col_i);
		
		# remove the key fromt he row_nams_of href
		delete $col_names_of_href->{$col_name};
		delete $col_names_order_of_href->{$col_name};
		
		# if there are no more cols then reset the table
		if ( $self->is_empty() ) {
			$self->reset();
		}
		
		return 1;
	}
	
	sub _drop_col_checks {
		my ($self, $col_name) = @_;
		
		# make sure the parameter values are defined
		_check_defined($col_name, "col_name");
		
		# ensure the row is actually in the table
		if ( ! $self->has_col($col_name) ) {
			MyX::Table::Col::UndefName->throw(
				error => "Col ($col_name) is not in Table\n",
				name => $col_name
			);
		}
		
		return 1;
	}
	
	sub _decrement_name_indicies {
		my ($href, $i) = @_;
		
		my $val;
		foreach my $key ( keys %{$href} ) {
			#print "key: $key\n";
			$val = $href->{$key};
			if ( $val > $i ) {
				$href->{$key} = $val - 1;
			}
		}
		
		return 1;
	}
	
	sub subset {
		my ($self, $params_href) = @_;
		# the params can include values such as:
		# rows, cols, drop
		
		# check the parameter values and set defaults as necessary
		$self->_check_subset_params($params_href);
		
		# some variables
		my $rows_href = $params_href->{rows};
		my $cols_href = $params_href->{cols};
		my $drop = $params_href->{drop};
		
		# drop the rows first because they are easier and faster to drop
		foreach my $r ( @{$self->get_row_names()} ) {
			if ( $drop == 0 and ! defined $rows_href->{$r} ) {
				$self->drop_row($r);
			}
			elsif ( $drop == 1 and defined $rows_href->{$r} ) {
				$self->drop_row($r);
			}
		}
		foreach my $c ( @{$self->get_col_names()} ) {
			if ( $drop == 0 and ! defined $cols_href->{$c} ) {
				$self->drop_col($c);
			}
			elsif ( $drop == 1 and defined $cols_href->{$c} ) {
				$self->drop_col($c);
			}
		}

		return(1);
	}
	
	sub _check_subset_params {
		my ($self, $params_href) = @_;
		
		# I frequently mistakenly use "col" or "row" as the parameter value
		# and that problem is hard to debug, so I am going to through an error
		# if I encounter this problem
		if ( _is_defined($params_href->{col}) ) {
			$params_href->{cols} = $params_href->{col};
		}
		if ( _is_defined($params_href->{row}) ) {
			$params_href->{rows} = $params_href->{row};
		}
		
		# NOTE: if drop is set to TRUE and rows (or cols) is not defined then
		#		naturally all the rows would be removed.  That functionality
		#		seemed counterintuitive to me.  So now when drop is set to
		#		TRUE (indicating to remove the given rows or cols) then the
		#		default will be to keep all the rows (or cols) if there is
		# 		nothing explicetly designated to be removed.  For example,
		#		subset({drop => "T"}) will leave the table unchaged as opposed
		# 		to removing everything.
		
		# if drop is not set then keep all the given rows and cols
		# this drop block must go before the checks for rows and cols
		if ( _is_defined($params_href->{drop}) ) {
			$params_href->{drop} = to_bool($params_href->{drop});
			
			# if either the rows or cols params is not set then set it to
			# all the rows or cols.  see note above.
			if ( $params_href->{drop} == 1 and
				! _is_defined($params_href->{rows}) ) {
				$params_href->{rows} = [];
			}
			if ( $params_href->{drop} == 1 and
				(! _is_defined($params_href->{cols})) ) {
				$params_href->{cols} = [];
			}
		}
		else {
			$params_href->{drop} = 0; # set to false as defualt
		}
		
		# if rows is not set then keep all rows
		if ( ! _is_defined($params_href->{rows}) ) {
			$params_href->{rows} = aref_to_href($self->get_row_names());
		}
		
		# check the row type
		if ( ref($params_href->{rows}) eq "ARRAY" ) {
			$params_href->{rows} = aref_to_href($params_href->{rows});
		}
		check_ref($params_href->{rows}, "HASH");
		
		# if cols is not set then keep all cols
		if ( ! _is_defined($params_href->{cols}) ) {
			$params_href->{cols} = aref_to_href($self->get_col_names());
		}
		
		# check the col type
		if ( ref($params_href->{cols}) eq "ARRAY" ) {
			$params_href->{cols} = aref_to_href($params_href->{cols});
		}
		check_ref($params_href->{cols}, "HASH");
		
		# make sure the rows and cols specified are actually in the table??
		
		return($params_href);
	}
	
	sub merge {
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
		_check_defined($params_href->{y_tbl}, "y_tbl");
		
		if ( ref $params_href->{y_tbl} ne "Table" ) {
			MyX::Generic::Ref::UnsupportedType->throw(
				error => "y_tbl must be of type Table\n"
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
	
	sub cbind {
		my ($self, $tbl2) = @_;
		
		# binds tables together by column
		
		# check that the tbl2 parameter is defined
		_check_defined($tbl2, "tbl2");
		
		# check that the tbl2 parameter is a Table object
		check_ref($tbl2, "Table");
		
		# check that the number of rows in each column are equal length
		if ( $self->get_row_count() != $tbl2->get_row_count() ) {
			MyX::Table::Bind::NamesNotEquiv->throw(
				error => "Row names not equivalent length in cbind\n"
			);
		}
		
		# check that the row names in each table match
		my $lc = List::Compare->new(
			$self->get_row_names(),
			$tbl2->get_row_names()
		);
		if ( ! $lc->is_LequivalentR() ) {
			MyX::Table::Bind::NamesNotEquiv->throw(
				error => "Row names not equivalent in cbind\n"
			);
		}
		
		foreach my $c ( @{$tbl2->get_col_names()} ) {
			# note that when I try to add the column to self it will
			# automatically check that the column name is not already in self
			$self->add_col($c, $tbl2->get_col($c), $tbl2->get_row_names());
		}
		
		return(1);
	}
	
	sub rbind {
		my ($self, $tbl2) = @_;
		
		# binds tables together by row
		
		# check that the tbl2 parameter is defined
		_check_defined($tbl2, "tbl2");
		
		# check that the tbl2 parameter is a Table object
		check_ref($tbl2, "Table");
		
		# check that the number of cols in each row are equal length
		if ( $self->get_col_count() != $tbl2->get_col_count() ) {
			MyX::Table::Bind::NamesNotEquiv->throw(
				error => "Col names not equivalent length in rbind\n"
			);
		}
		
		# check that the col names in each table match
		my $lc = List::Compare->new(
			$self->get_col_names(),
			$tbl2->get_col_names()
		);
		if ( ! $lc->is_LequivalentR() ) {
			MyX::Table::Bind::NamesNotEquiv->throw(
				error => "Col names not equivalent in cbind\n"
			);
		}
		
		foreach my $r ( @{$tbl2->get_row_names()} ) {
			# note that when I try to add the row to self it will
			# automatically check that the row name is not already in self
			$self->add_row($r, $tbl2->get_row($r), $tbl2->get_col_names());
		}
		
		return(1);
	}
	
	sub transpose {
		my ($self) = @_;
		
		# make a copy of self to temporarily preserve the data
		my $orig = $self->copy();
		
		# reset self
		$self->reset();
		
		# set the row names header
		$self->_set_row_names_header($orig->get_row_names_header());
		
		# for each column in the old table add that column as a row in the
		# new table
		my $by_index = 1; # TRUE
		foreach my $c ( @{$orig->get_col_names($by_index)} ) {
			$self->add_row($c, $orig->get_col($c), $orig->get_row_names($by_index));
		}
		
		# delete the temporary original object
		# ? not sure how to do this.  It's probably not neccessary anyway
		
		return 1;
	}
	
	sub reset {
		my ($self) = @_;
		
		$self->_set_row_count(0);
		$self->_set_col_count(0);
		$row_names_of{ident $self} = undef;
		$col_names_of{ident $self} = undef;
		$row_names_order_of{ident $self} = undef;
		$col_names_order_of{ident $self} = undef;
		$row_names_header_of{ident $self} = undef;
		$mat_of{ident $self} = undef;
		
		return 1;
	}
	
	sub copy {
		my ($self) = @_;
		my $copy = Table->new();
		
		# copy the row names header
		$copy->_set_row_names_header($self->get_row_names_header());

		
		# copy each row of data from self to copy
		my $row_i = 0;
		foreach my $r ( @{$self->get_row_names()} ) {
			$row_i++;
			$copy->add_row($r, $self->get_row($r), $self->get_col_names());
		}
		
		return($copy);
	}
	
	sub has_row {
		my ($self, $row) = @_;
		
		_check_defined($row);
		
		if ( defined $row_names_of{ident $self}->{$row} ) {
			return 1;  # TRUE
		}
		else {
			return 0; # FALSE
		}
	}
	
	sub has_col {
		my ($self, $col) = @_;
		
		_check_defined($col);
		
		if ( defined $col_names_of{ident $self}->{$col} ) {
			return 1;  # TRUE
		}
		else {
			return 0; # FALSE
		}
	}
	
	sub has_row_names_header {
		my ($self) = @_;
		
		if ( defined $row_names_header_of{ident $self} ) {
			return 1;
		}
		
		# else
		return 0;
	}
	
	sub is_empty {
		my ($self) = @_;
		
		if ( $self->get_row_count() <= 0 or
			 $self->get_col_count() <= 0  ) {
			return 1;  # TRUE
		}
		
		return 0; # FALSE
	}
	
	sub _load_case_4_or_5 {
		my ($self, $FH, $sep, $comm_char, $skip_after, $skip_before) = @_;
		
		# Case 4 and 5: has_col_header == T AND has_row_names == T. These only
		# differ because there might be an optional header for the row names. To
		# determine if there is I will have to look at the second line (ie first
		# line of values).
		
		my $is_header_line = 1;
		my $is_first_line = 0; # this is the first data line
        my $line_number = 1;  # line number is 1-based
		my @col_headers = ();
		my @row_names = ();
		my @tbl = ();
		
		foreach my $line ( <$FH> ) {
			chomp $line;
           
            # check if we should be skipping lines 
            if ( _is_skip_after($line_number, $skip_after) ) { last; }
            if ( _is_skip_before($line_number, $skip_before) ) { 
                $line_number++;
                next; 
            }

            # increment the line number here but don't use it after this
            $line_number++;

            # check if the line starts with a comment character
            if ( _is_comment($line, $comm_char) ) { next; }
            
            # check if the line is only whitespace
            if ( _is_whitespace($line) ) { next; }

			my @vals = split(/$sep/, $line);
			
			# check if the line ends in sep
			if ( $line =~ m/$sep$/ ) {
				push @vals, ("") x _count_end_seps($line, $sep);
			}
			
			if ( $is_header_line == 1 ) {
				# add the headers assuming there is now row_name_header
				# when we look at the next line we can tell if there is a
				# row_name_header and adjust accordingly
				@col_headers = split(/$sep/, $line);
				$self->_set_col_count(scalar @col_headers);
				$self->_set_col_names(\@col_headers);
				$self->_set_row_names_header(undef);
				
				$is_header_line = 0;
				$is_first_line = 1;
				
				next; # go to the next line
			}
			elsif ( $is_first_line == 1 ) {
				$self->_check_header_format(scalar @vals);
				$is_first_line = 0;
				# don't go to the next line yet because i need to save the row
			}
			
			# save the row
			push @row_names, shift @vals;
			push @tbl, \@vals;
		}
		
		# set the row names
		$self->_set_row_count(scalar @row_names);
		$self->_set_row_names(\@row_names);
		
		# set the matrix
		$mat_of{ident $self} = \@tbl;
		
		return 1;
	}
	
	sub _load_case_3 {
		my ($self, $FH, $sep, $comm_char, $skip_after, $skip_before) = @_;
		
		# Case 3: has_col_header == T AND has_row_names == F AND has_row_header == F
		# Table needs the default row names and already has col headers
		
		my $is_first_line = 1;
        my $line_number = 1;  # line number is 1-based
		my @row_names = ();
		my $row_count = 0;
		my @col_headers = ();
		my @tbl = ();
		
		foreach my $line ( <$FH> ) {
			chomp $line;
            
            # check if we should be skipping lines 
            if ( _is_skip_after($line_number, $skip_after) ) { last; }
            if ( _is_skip_before($line_number, $skip_before) ) { 
                $line_number++;
                next; 
            }

            # increment the line number here but don't use it after this
            $line_number++;
            
            # check if the line starts with a comment character
            if ( _is_comment($line, $comm_char) ) { next; }
            
            # check if the line is only whitespace
            if ( _is_whitespace($line) ) { next; }
            
			my @vals = split(/$sep/, $line);
			
			# check if the line ends in sep
			if ( $line =~ m/$sep$/ ) {
				push @vals, ("") x _count_end_seps($line, $sep);
			}
			
			# use the first line to get the number of columns to set the headers
			if ( $is_first_line == 1 ) {
				@col_headers = split(/$sep/, $line);
				$self->_set_col_count(scalar @col_headers);
				$self->_set_col_names(\@col_headers);
				$self->_set_row_names_header(undef);
				$is_first_line = 0;
				next; # to go the next line
			}
			
			# generate default row names
			push @row_names, $row_count;
			push @tbl, \@vals;
			$row_count++;
		}
		
		# set the row names
		$self->_set_row_count(scalar @row_names);
		$self->_set_row_names(\@row_names);
		
		# set the matrix
		$mat_of{ident $self} = \@tbl;
		
		return 1;
	}
	
	sub _load_case_2 {
		my ($self, $FH, $sep, $comm_char, $skip_after, $skip_before) = @_;
		
		# Case 2: has_col_header == F AND has_row_names == T AND has_row_header == F
		# Table needs the default col header and already has row names
		
		my $is_first_line = 1;
        my $line_number = 1;  # line number is 1-based
		my @row_names = ();
		my @tbl = ();
		
		foreach my $line ( <$FH> ) {
			chomp $line;

            # check if we should be skipping lines 
            if ( _is_skip_after($line_number, $skip_after) ) { last; }
            if ( _is_skip_before($line_number, $skip_before) ) { 
                $line_number++;
                next; 
            }
            
            # increment the line number here but don't use it after this
            $line_number++;
            
            # check if the line starts with a comment character
            if ( _is_comment($line, $comm_char) ) { next; }
            
            # check if the line is only whitespace
            if ( _is_whitespace($line) ) { next; }
    
			my @vals = split(/$sep/, $line);
			
			# check if the line ends in sep
			if ( $line =~ m/$sep$/ ) {
				push @vals, ("") x _count_end_seps($line, $sep);
			}
			
			# use the first line to get the number of columns to set the headers
			if ( $is_first_line == 1 ) {
				$self->_set_default_col_headers(scalar @vals - 1);
				$is_first_line = 0;
			}
			
			push @row_names, shift @vals;
			push @tbl, \@vals;
		}
		
		# set the row names
		$self->_set_row_count(scalar @row_names);
		$self->_set_row_names(\@row_names);
		
		# set the matrix
		$mat_of{ident $self} = \@tbl;
		
		return 1;
	}
	
	sub _load_case_1 {
		my ($self, $FH, $sep, $comm_char, $skip_after, $skip_before) = @_;
		
		# Case 1: has_col_header == F AND has_row_names == F AND has_row_header == F
		# Table is purly a matrix of values so I need to add col headers and
		# row names
		
		my $is_first_line = 1;
        my $line_number = 1;  # line number is 1-based
		my $row_count = 0;
		my @row_names = ();
		my @tbl = ();
		
		foreach my $line ( <$FH> ) {
			chomp $line;

            # check if we should be skipping lines 
            if ( _is_skip_after($line_number, $skip_after) ) { last; }
            if ( _is_skip_before($line_number, $skip_before) ) { 
                $line_number++;
                next;
            }
            
            # increment the line number here but don't use it after this
            $line_number++;
            
            # check if the line starts with a comment character
            if ( _is_comment($line, $comm_char) ) { next; }

            # check if the line is only whitespace
            if ( _is_whitespace($line) ) { next; }
    
			my @vals = split(/$sep/, $line);
			
			# check if the line ends in sep
			if ( $line =~ m/$sep$/ ) {
				push @vals, ("") x _count_end_seps($line, $sep);
			}
			
			# use the first line to get the number of columns to set the headers
			if ( $is_first_line == 1 ) {
				$self->_set_default_col_headers(scalar @vals);
				$is_first_line = 0;
			}
			
			# generate defualt row names
			push @row_names, $row_count;
			push @tbl, \@vals;
			$row_count++;
		}
		
		# set the row names
		$self->_set_row_count(scalar @row_names);
		$self->_set_row_names(\@row_names);
		
		# set the matrix
		$mat_of{ident $self} = \@tbl;
		
		return 1;
	}

    sub _is_comment {
        my ($line, $comm_char) = @_;

        if ( ! defined $comm_char ) { return 0; }
        if ( $line =~ m/^\s*$comm_char/ ) { return 1; }

        return(0);
    }

    sub _is_skip_after {
        my ($line_num, $skip_after) = @_;

        if ( ! defined $skip_after ) { return 0; }
        if ( $line_num > $skip_after ) { return 1; }

        return(0);
    }
    
    sub _is_skip_before {
        my ($line_num, $skip_before) = @_;

        if ( ! defined $skip_before ) { return 0; }
        if ( $line_num < $skip_before ) { return 1; }

        return(0);
    }

    sub _is_whitespace {
        my ($line) = @_;

        if ($line =~ /^\s*$/) { return(1); }
        return(0);
    }
	
	sub _set_default_col_headers {
		my ($self, $len) = @_;
		
		# set col count
		$self->_set_col_count($len);
		
		# set col headers (with no row names header)
		$len--; # convert to index
		my @col_names = (0..$len);
		$self->_set_col_names(\@col_names);
		$self->_set_row_names_header(undef);
		
		return 1;
	}
	
	sub _check_header_format {
		my ($self, $line_vals_count) = @_;
		
		if ( $line_vals_count - 1 == $self->get_col_count() ) {
			# this is the case where the number of header values is the same
			# as the number of items in the row when you exclude the row name.
			# here I want to do nothing
			;
		}
		elsif ( $line_vals_count == $self->get_col_count() ) {
			# in this case the rows were given a header value
			# remove that header value from the column names, but record it
			# in the row_names_header attribute
			my @col_names_arr = @{$self->get_col_names()};
			my $row_names_header = shift @col_names_arr;
			$self->_set_row_names_header($row_names_header);
			$self->_set_col_count(scalar @col_names_arr);
			$self->_set_col_names(\@col_names_arr);
		}
		else {
			# in this case there must be an error.  the number of headers in no
			# way matches the number of values in row one
			MyX::Table::BadDim->throw(
				error => "Headers count doesn't match row 1 values count\n"
			);
		}
		
		return 1;
	}
	
	sub _count_end_seps {
		my ($line, $sep) = @_;
		
		my $count = 0;
		
		while ( $line =~ m/$sep$/ ) {
			$line =~ s/$sep$//;
			$count++;
		}
		
		return($count);
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
		_check_defined($file, "file");
		
		# check if the file exists
		if ( ! -f $file ) {
			MyX::Generic::DoesNotExist::File->throw(
				error => "File ($file) does not exist\n"
			)
		}
		
		# check that the file is non empty
		if ( ! -s $file ) {
			MyX::Generic::File::Empty->throw(
				error => "File ($file) is empty\n"
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

    sub _set_comm_char { 
        my ($comm_char) = @_;

        if ( ! defined $comm_char ) {
            return($COMM_CHAR);
        }

        return($comm_char);
    }
    
    sub _set_skip_after {
        my ($skip_after) = @_;

        if ( ! defined $skip_after ) {
            return($SKIP_AFTER);
        }

        # make sure it is a digit >= 0
        # remember the skip args are 1-based
        # so setting to 0 will skip the whole file
        
		# check if row_count is a number
		if ( ! looks_like_number($skip_after) ) {
			MyX::Generic::Digit::MustBeDigit->throw(
				error => "skip_after argument must be a digit > 0\n"
			);
		}
		
		# make sure the number is >= 0
		if ( $skip_after < 0 ) {
			MyX::Generic::Digit::TooSmall->throw(
				error => "skip_after argument must be a digit > 0\n"
			);
		}

        return($skip_after);
    }
	
    sub _set_skip_before {
        my ($skip_before) = @_;

        if ( ! defined $skip_before ) {
            return($SKIP_AFTER);
        }

        # make sure it is a digit >= 0
        # remember the skip args are 1-based
        # so setting to 0 or 1 will skip nothing
        
		# check if row_count is a number
		if ( ! looks_like_number($skip_before) ) {
			MyX::Generic::Digit::MustBeDigit->throw(
				error => "skip_before argument must be a digit > 0\n"
			);
		}
		
		# make sure the number is >= 0
		if ( $skip_before < 0 ) {
			MyX::Generic::Digit::TooSmall->throw(
				error => "skip_before argument must be a digit > 0\n"
			);
		}

        return($skip_before);
    }

	sub _has_col_headers {
		my ($bool) = @_;
		
		if ( _is_defined($bool) ) {
			return _to_bool($bool);
		}
		
		return 1;  # the default is that it has header (ie true)
	}
	
	sub _has_row_names {
		my ($bool) = @_;
		
		if ( _is_defined($bool) ) {
			return _to_bool($bool);
		}
		
		return 1; # the default is that it has row headers (ie true)
	}
	
	sub _check_row_name {
		my ($self, $row) = @_;
		
		# check if the row parameter is defined
		_check_defined($row, "row");
		
		# check if the row exists in the table
		my $row_href = $row_names_of{ident $self};
		if ( ! defined $row_href->{$row} ) {
			MyX::Table::Row::UndefName->throw(
				error => "Undefined row name: $row\n",
				name => $row
			);
		}
		
		return 1;
	}
	
	sub _check_col_name {
		my ($self, $col) = @_;
		
		# check if the col parameter is defined
		_check_defined($col, "col");
		
		# check if the col exists in the table
		my $col_href = $col_names_of{ident $self};
		if ( ! defined $col_href->{$col} ) {
			MyX::Table::Col::UndefName->throw(
				error => "Undefined col name: $col\n",
				name => $col
			);
		}
		
		return 1;
	}
	
	sub _check_defined {
		my ($val, $val_name) = @_;
		
		if ( ! defined $val ) {
			MyX::Generic::Undef::Param->throw(
				error => "Undefined parameter value ($val_name)\n"
			);
		}
		
		return 1;
	}
	
	sub _is_defined {
		my ($val) = @_;
		
		if ( ! defined $val ) {
			return 0;
		}
		
		return 1;
	}
	
	sub _is_aref {
		my ($aref, $name) = @_;
		
		if ( ref($aref) ne "ARRAY" ) {
			MyX::Generic::Ref::UnsupportedType->throw(
				error => "$name must be an array reference\n"
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

This document describes Table version 0.0.2


=head1 SYNOPSIS

    use Table;
	
	# create an empty table object
	my $table = Table->new();

	# load the table from a file
	$table->load_from_file("my_table.txt", "\t");
	$table->load_from_file({
        file => "my_table.txt", 
        sep => "\t", 
        has_col_header => "T",
        has_row_names => "T",
        comm_char => "#"
        skip_after => 10
        skip_before => 2
    });
	
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
	$table->to_str({sep => "\t"});
	
	# print the CSV string
	$table->to_str(",");
	$table->to_str({sep => ","});
	
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
	});
	
	# subset a table
	# note this permenently removes what is left out
	$tbl1->subset({
		rows => $rows_to_keep_aref,
		cols => $cols_to_keep_aref,
	});
	
	# you can also subset by dropping rows or cols
	$tbl1->subset({
		rows => $rows_to_drop_aref,
		cols => $cols_to_drop_aref,
		drop => "T"
	});
	
	# sort by a column
	my $numeric = 1; # TRUE
	my $decending = 1; # TRUE
	$table->sort_by_col($col_name, $numeric, $decending);
	
	# order rows
	my @new_order = (<ROW NAMES>);  # an array of row names
	$table->order_rows(\@new_order);
	
	# order columns
	my @new_order = (<COL NAMES>);  # an array of col names
	$table->order_cols(\@new_order);
  
  
=head1 DESCRIPTION

This module is an object for storing and opperating on tables (ie 2D matrix).
The data structure is implemented as an array of arrays.  The column and row
names are stored in hashes where the value associated with each name is the
index at which it is found in the array.  This allows fast access via the column
and row names.  The column names should be unique and the row names should be
unique.  In other words, there cannot be two rows with the name "A".  Similarly,
there cannot be two columns with the name "A".  There can be one column named
"A" and one row names "A" in the same table.  If the row or column names in your
table are not unique you can let has_row_names and has_col_header to "False".
See the documentation for load_from_file() for more details.

There are two recommend ways to populate a table object:

1) load_from_file -- this function parses through a plain text file to populate
the table object. The default arguments assume the table in the file has both
row names and column headers. However, tables without row names or without
column headers are also valid. Additionally the row names can include a header
value or not. The sep option can be used to specify a delimiter for your file
(ie "\t", ",", etc).  This is the recommended and most simple way to populate a
table object. See the documentation for load_from_file() for usage details.

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
use List::Compare;
MyX::Generic
version our $VERSION
UtilSY qw(aref_to_href href_to_aref check_ref to_bool)


=head1 INCOMPATIBILITIES

None reported.


=head1 METHODS

=over
	
	# Constructor #
	new
	
	# Getters #
	get_row_count
	get_col_count
	get_row_names
	get_col_names
	get_col_headers
	get_value_at
	get_value_at_fast
	get_row
	get_col
	get_row_index
	get_col_index
	get_row_names_header

	# Setters #
	set_value_at
	_set_row_count
	_set_col_count
	_set_row_names
	_set_col_names
	_set_col_headers
	_set_row_names_header

	# Others #
	load_from_file;
	load_from_href_href
	order_rows
	order_cols
	sort_by_col
	rekey_row_names
	rekey_col_headers
	save
	to_str
    change_row_name
    change_col_name
	add_row
	_add_row_checks
	add_col
	_add_col_checks
	drop_row
	_drop_row_checks
	drop_col
	_drop_col_checks
	_decrement_name_indicies
	subset
	_check_subset_params
	merge
	_check_merge_params
	cbind
	rbind
	transpose
	reset
	copy
	has_row
	has_col
	has_row_names_header
	is_empty
	_load_case_1
	_load_case_2
	_load_case_3
	_load_case_4_or_5
    _is_comment
    _is_skip_after
    _is_skip_before
    _is_whitespace
	_set_default_col_headers
	_check_header_format
	_count_end_seps
	_aref_to_href
	_check_file
	_set_sep
    _set_comm_char
    _set_skip_after
    _set_skip_before
	_has_col_headers
	_has_row_names
	_check_row_name
	_check_col_name
	_check_defined

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
	
=head2 get_col_headers

	Title: get_col_headers
	Usage: $obj->get_col_headers($by_index)
	Function: Returns the column names in the order of their index
	Returns: aref
	Args: -by_index => an optional booling indicating to get the column headers
	                   ordered by their index in the actual table and NOT their
					   defined sorted order
	Throws: NA
	Comments: This is an alternate name for get_col_names.  It functions exactly
	          the same.
	See Also: get_col_names
	
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
	
=head2 _set_col_headers

	Title: _set_col_headers
	Usage: $obj->_set_col_headers($col_names_aref)
	Function: Sets the col headers
	Returns: 1 on success
	Args: -col_names_aref => array reference of col headers
	Throws: MyX::Table::BadDim
	        MyX::Table::NamesNotUniq
	Comments: PRIVATE!  Do NOT call this method outside of Table.pm.
	          This is an alternative way to _set_col_names.  They are exactly
			  the same
	See Also: _set_col_names
	
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
	Usage: $obj->load_from_file($args_href)
	Function: Loads the data from a delimited file
	Returns: 1 on success
	Args: -args_href => hash reference
	Throws: MyX::Generic::File::CannotOpen
	        MyX::Table::BadDim
	        MyX::Table::NamesNotUniq
			MyX::Generic::Digit::MustBeDigit
	        MyX::Generic::Digit::TooSmall
            MyX::Generic
	Comments: This is the recommended method to load data into a Table object.
	          These parameters can be included in the args_href:
			  file => file with table
			  sep => delimiter
			  has_col_headers => boolean
			  has_row_names => boolen
              comm_char => string
              skip_after => int
              skip_before => int
	
	          Usng the default settings it assumes the first line is the column
			  names and the first column is the row names (ie
			  has_col_header => "T", has_row_names => "T").
			  
			  The row names column (ie the first column) may have a name, but it
			  is not required.
			  
			  If the first row does not have header values the table can
			  still be loaded.  When calling the function, all the parameters
			  become required included the "has_col_header" boolean parameter.
			  The column headers will be set to integers from 0 to n-1 number of
			  columns in the table.
			  
			  If the first column does not have row names the table can
			  still be loaded.  When calling the function, all the parameters
			  become required included the "has_row_names" boolean parameter.
			  The row names will be set to integers from 0 to n-1 number of
			  rows in the table (excluding the header row).

              To ignore comment lines use the comm_char argument to define how
              comment lines are specified.  For example, if comment lines begin
              with the character "#" then pass comm_char => "#".  Comment lines
              are ignored when loading the file.  They are not saved in the 
              Table object and cannot be restored from a Table object.  Once
              the Table is loaded from the input file the comment lines are lost.
              Of course they will still be in the original file from which the
              Table is loaded as long as that file is not overwritten in any way.

              When the skip_after argument is supplied with an integer it will 
              ignore lines AFTER the specified skip_after argument.  For example,
              if skip_after => 2 only two lines in the file will be read.  The
              lines start at 1 (ie 1-based).  If skip_after => 0 no lines will be
              read.

              When the skip_after argument is supplied with an integer it will 
              ignore lines BEFORE the specified skip_before argument.  For
              example, if skip_before => 2 line 1 will be skipped.  The lines
              start at 1 (ie 1-based).  If skip_before => no lines will be 
              skipped.

              White space only lines are ignored.
	See Also: NA
	
=head2 order_rows

	Title: order_rows
	Usage: $obj->order_rows($row_names_aref)
	Function: Orders the table rows by the given row names
	Returns: 1 on success
	Args: -row_names_aref => aref of row names
	Throws: MyX::Generic::Undef::Param
			MyX::Generic::Ref::UnsupportedType
			MyX::Table::Order::Row::NamesNotEquiv
	Comments: The row names in the table and the given row names must be equal
			  sets.  They must have the exact same members.
	See Also: NA
	
=head2 order_cols

	Title: order_cols
	Usage: $obj->order_cols($row_names_aref)
	Function: Orders the table cols by the given col names
	Returns: 1 on success
	Args: -col_names_aref => aref of col names
	Throws: MyX::Generic::Undef::Param
			MyX::Generic::Ref::UnsupportedType
			MyX::Table::Order::Col::NamesNotEquiv
	Comments: The col names in the table and the given col names must be equal
			  sets.  They must have the exact same members.
	See Also: NA
	
=head2 sort_by_col

	Title: sort_by_col
	Usage: $obj->sort_by_col($col_name, $numeric, $decreasing)
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
	
=head2 rekey_row_names

	Title: rekey_row_names
	Usage: $obj->rekey_row_names($col_name, $new_col_header)
	Function: Re-key the rows in the table using the given column
	Returns: 1 on success
	Args: -col_name => name of column by which to re-key
		  -new_col_header => column header name to use for the old row names
	Throws: MyX::Table::Col::UndefName
	        MyX::Generic::Undef::Param
			MyX::Table::NamesNotUniq
	Comments: After re-keying a table it is no longer guaranteed to be sorted.
	          The new_col_header parameter is optional.  If there is no
			  row_names_header and new_col_header is not defined the column will
			  be named "old_row_names". The values in the column to use as the
			  new row keys must all be unique.  An error will be thrown if that
			  is not the case.
	See Also: NA
	
=head2 rekey_col_headers

	Title: rekey_col_headers
	Usage: $obj->rekey_col_headers($row_name, $new_row_name)
	Function: Re-key the columns in the table using the given row
	Returns: 1 on success
	Args: -row_name => name of row by which to re-key
		  -new_row_name => row header name to use for the old column names
	Throws: MyX::Table::Col::UndefName
	        MyX::Generic::Undef::Param
			MyX::Table::NamesNotUniq
	Comments: After re-keying a table it is no longer guaranteed to be sorted.
	          The new_row_header parameter is required because column headers
			  do not have a name like the row names have a header. Note that the
			  row_name cannot be saved and is lost when that row is set as the
			  new column headers.
	See Also: NA
	
=head2 save

	Title: save
	Usage: $obj->save($args_href)
	Function: Outputs the Table as text in the given file
	Returns: 1 on success
	Args: -args_href => hash reference with params
	Throws: MyX::Generic::File::CannotOpen
	Comments: The parameter values include:
	          file => path to output file
	          sep => delimiter string
		      print_col_header => boolean
			  print_row_names => boolean
			  
			  The default values include
			  sep => "\t"
			  print_col_header => "T"
			  print_row_names => "T"
	See Also: NA
	
=head2 to_str

	Title: to_str
	Usage: $obj->to_str($args_href)
	Function: Returns the Table as a string
	Returns: str
	Args: -args_href => hash reference
	Throws: NA
	Comments: The parameters can be used as follows:
	          sep => "\t",
			  print_col_header => "T"
			  print_row_names => "T"
			  
			  The settings above are the default settings.
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
	
=head2 subset

	Title: subset
	Usage: subset($params_href)
	Function: Subsets the table
	Returns: 1 on success
	Args: -params_href => href of subset parameters (see Comments)
	Throws: MyX::Generic::Ref::UnsupportedType
			MyX::Generic::Undef::Param
	Comments: The params_href can have the following features:
	          params_href{rows => aref or href,
			              cols => aref or href,
						  drop => boolean}
			  The rows and cols parameters can be an array reference or hash
			  reference with row and column names.  If hash references are used
			  the names must be the keys.  I would recommend using the array
			  reference option for these.  If rows are passed that are not in
			  the table they are quietly ignored.  So if you subset a table
			  attempting to get a single row that is not in the table it
			  essentially empties the table. If either the rows (or cols)
			  parameter is not passed all the rows (or cols) are kept.
			  
			  drop is a boolean value indicating that the provided rows and cols
			  should be dropped from the table instead of kept. If you set drop
			  to "T" and don't provide a list of rows then all the rows will be
			  kept.  Cols perform similarly.  So the only way to drop all the
			  rows or cols would be to explicitly list them all in rows or cols.
			  However, if you want to do that you can simply call the empty()
			  function.
			  
			  Importantly, once you subset a table there is no way to reverse
			  the operation.  So if you want to subset without losing the
			  excluded rows and columns you should copy() the table before
			  executing subset().
	See Also: NA
	
=head2 _check_subset_params

	Title: _check_subset_params
	Usage: _check_subset_params($params_href)
	Function: Checks the subset parameters for errors
	Returns: Table
	Args: -params_href => href of subset parameters (see Comments)
	Throws: MyX::Generic::Ref::UnsupportedType
			MyX::Generic::Undef::Param
	Comments: This function is PRIVATE!  It should not be invoked by the average
	          user outside of Table.pm. The params_href can have the
			  following features:
	          params_href{rows => aref or href,
			              cols => aref or href,
						  drop => boolean}
	See Also: Table::subset
	
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
			  
			  This function is horribly memory inefficient.  It will need to be
			  optimized at a later date.
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

=head2 cbind

	Title: cbind
	Usage: $tbl1->cbind($tbl2)
	Function: Binds two tables together by concatenating their columns
	Returns: 1 on success
	Args: -tbl2 => Table object to bind to tbl1
	Throws: MyX::Table::Bind::NamesNotEquiv
			MyX::Generic::Ref::UnsupportedType
			MyX::Generic::Undef::Param
	Comments: When running cbind the row names in tbl1 and tbl2 must exact sets
			  of each other.  If there are extra rows in either table or the
			  row names are different a MyX::Table::Bind::NamesNotEquiv error
			  will be thrown.
	See Also: NA
	
=head2 rbind

	Title: rbind
	Usage: $tbl1->rbind($tbl2)
	Function: Binds two tables together by concatenating their rows
	Returns: 1 on success
	Args: -tbl2 => Table object to bind to tbl1
	Throws: MyX::Table::Bind::NamesNotEquiv
			MyX::Generic::Ref::UnsupportedType
			MyX::Generic::Undef::Param
	Comments: When running cbind the col names in tbl1 and tbl2 must exact sets
			  of each other.  If there are extra columns in either table or the
			  column names are different a MyX::Table::Bind::NamesNotEquiv error
			  will be thrown.
	See Also: NA

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

=head2 _load_case_1

	Title: _load_case_1
	Usage: $obj->_load_case_1($FH, $sep, $comm_char, $skip_after, $skip_before)
	Function: Loads a file with no col headers and no row names
	Returns: bool (0 | 1)
	Args: -FH => file handle
          -sep => delimiter
          -comm_char => comment character
          -skip_after => skip lines after this
          -skip_before => skip lines before this
	Throws: NA
	Comments: This function is PRIVATE!  It should not be invoked by the average
	          user outside of Table.pm.  
	See Also: NA
	
=head2 _load_case_2

	Title: _load_case_2
	Usage: $obj->_load_case_2($FH, $sep, $comm_char, $skip_after, $skip_before)
	Function: Loads a file with no col headers but has row names
	Returns: bool (0 | 1)
	Args: -FH => file handle
          -sep => delimiter
          -comm_char => comment character
          -skip_after => skip lines after this
          -skip_before => skip lines before this
	Throws: NA
	Comments: This function is PRIVATE!  It should not be invoked by the average
	          user outside of Table.pm.  
	See Also: NA
	
=head2 _load_case_3

	Title: _load_case_3
	Usage: $obj->_load_case_3($FH, $sep, $comm_char, $skip_after, $skip_before)
	Function: Loads a file with col headers but no row names
	Returns: bool (0 | 1)
	Args: -FH => file handle
          -sep => delimiter
          -comm_char => comment character
          -skip_after => skip lines after this
          -skip_before => skip lines before this
	Throws: NA
	Comments: This function is PRIVATE!  It should not be invoked by the average
	          user outside of Table.pm.  
	See Also: NA
	
=head2 _load_case_4_or_5

	Title: _load_case_4_or_5
	Usage: $obj->_load_case_4_or_5($FH, $sep, $comm_char, $skip_after, $skip_before)
	Function: Loads a file with col headers and row names
	Returns: bool (0 | 1)
	Args: -FH => file handle
          -sep => delimiter
          -comm_char => comment character
          -skip_before => skip lines before this
          -skip_after => skip lines after this
	Throws: NA
	Comments: This function is PRIVATE!  It should not be invoked by the average
	          user outside of Table.pm.  Case 4 is when there is no column
			  header for the row names.
	See Also: NA

=head2 _is_comment

	Title: _is_comment
	Usage: _is_comment($line, $comm_char)
	Function: Tests if a line is a comment or not
	Returns: bool (0 | 1)
	Args: -line => line string
          -comm_char => comment character
	Throws: NA
	Comments: This function is PRIVATE!  It should not be invoked by the average
	          user outside of Table.pm.  By default there is no comment character.
	See Also: NA
	
=head2 _is_skip_after

	Title: _is_skip_after
	Usage: _is_skip_after($line_num, $skip_after)
	Function: Tests if a line should be skipped because it is after $skip_after
	Returns: bool (0 | 1)
	Args: -line_num => current line number
          -skip_after => integer after which lines should be skipped
	Throws: NA
	Comments: This function is PRIVATE!  It should not be invoked by the average
	          user outside of Table.pm.  The default is set as undef which will not
              skip any lines.  If $skip_after => 0 all lines are skipped.
	See Also: NA
	
=head2 _is_skip_before

	Title: _is_skip_before
	Usage: _is_skip_before($line_num, $skip_before)
	Function: Tests if a line should be skipped because it is before $skip_before
	Returns: bool (0 | 1)
	Args: -line_num => current line number
          -skip_before => integer before which lines should be skipped
	Throws: NA
	Comments: This function is PRIVATE!  It should not be invoked by the average
	          user outside of Table.pm.  The default is set as undef which will not
              skip any lines.  If $skip_before => 1 no lines are skipped.
	See Also: NA

=head2 _is_whitespace

	Title: _is_whitespace
	Usage: _is_whitespace($line)
	Function: Tests if a line is only whitespace
	Returns: bool (0 | 1)
	Args: -line => line string
	Throws: NA
	Comments: This function is PRIVATE!  It should not be invoked by the average
	          user outside of Table.pm.  Lines that only consist of white space
              are remove/ignored.  However, they are still counted as a line for
              the purpose of providing skip_before and skip_after values.
	See Also: NA

=head2 _set_default_col_headers

	Title: _set_default_col_headers
	Usage: $obj->_set_default_col_headers($first_line_vals_count)
	Function: Checks if one of the column headers is the row name header
	Returns: bool (0 | 1)
	Args: -first_line_vals_count => number of values in first line
	Throws: NA
	Comments: This function is PRIVATE!  It should not be invoked by the average
	          user outside of Table.pm.  
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
	
=head2 _count_end_seps

	Title: _count_end_seps
	Usage: $obj->_count_end_seps($str, $sep)
	Function: Counts the number of sep characters trailing in the string
	Returns: int
	Args: -str => string
	      -sep => delimiter
	Throws: NA
	Comments: This function is PRIVATE!  It should not be invoked by the average
	          user outside of Table.pm.  This function helps with the case when
			  there are trailing delimiters on a line (ie empty cells at the
			  end of the line.)
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

=head2 _set_comm_char

	Title: _set_comm_char
	Usage: _set_comm_char($comm_char)
	Function: Sets the comment character
	Returns: str
	Args: -comm_char => comment character
	Throws: NA
	Comments: This function is PRIVATE!  It should not be invoked by the average
	          user outside of Table.pm.  If the sep parameter is not defined
			  the defualt is returned.  Currently the default is set to undef,
              meaning there are no comments in the file.  Note that the comment
              character is not a Table attribute.  It is not saved in the Table
              object.  It is only considered when calling the load_from_file
              function.
	See Also: NA

=head2 _set_skip_after

	Title: _set_skip_after
	Usage: _set_skip_after($skip_after)
	Function: Checks the skip_after value to make sure it is defined and valid
	Returns: int
	Args: -skip_after => start skipping lines at line number $skip_after
	Throws: MyX::Generic::Digit::MustBeDigit
	        MyX::Generic::Digit::TooSmall
	Comments: This function is PRIVATE!  It should not be invoked by the average
	          user outside of Table.pm.  If the skip_after parameter is not defined
			  the defualt is returned.  Currently the default is set to undef.
              The $skip_after argument must be an int >= 0.  When 0 is supplied
              all lines are skipped resulting in an empty table.
	See Also: NA
	
=head2 _set_skip_before

	Title: _set_skip_before
	Usage: _set_skip_before($skip_before)
	Function: Checks the skip_before value to make sure it is defined and valid
	Returns: int
	Args: -skip_before => skip lines before line number $skip_before
	Throws: MyX::Generic::Digit::MustBeDigit
	        MyX::Generic::Digit::TooSmall
	Comments: This function is PRIVATE!  It should not be invoked by the average
	          user outside of Table.pm.  If the skip_before parameter is not defined
			  the defualt is returned.  Currently the default is set to undef.
              The $skip_before argument must be an int >= 0.  When 0 or 1 is 
              supplied no lines are skipped.
	See Also: NA
	
=head2 _has_col_headers

	Title: _has_col_headers
	Usage: _has_col_headers($bool)
	Function: Checks has_col_headers boolean
	Returns: bool
	Args: -bool => boolean value (0 | 1 | T | F | true | false)
	Throws: NA
	Comments: This function is PRIVATE!  It should not be invoked by the average
	          user outside of Table.pm.  If the bool argument is not defined
			  the defualt is returned.  Currently the default is set to "T".
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

=head2 Table::Big

Make a Table object that can handle very large tables.  If I can 
write this on top of C or C++ code to optimize memory and speed
performance

=head2 Table::Sparse

Make a Table object that can handle sparse tables.

=head2 Optimize merge function

It uses a ton of memory.

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


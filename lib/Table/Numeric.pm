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
	sub increment_at;
	sub decrement_at;
	
	



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
		my $new_tbl = Table::Numeric->new();
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

	sub increment_at {
		my ($self, $row, $col, $val) = @_;

		if ( ! defined $val ) { $val = 1; }

		my $new_val = $self->get_value_at($row, $col) + $val;
		$self->set_value_at($row, $col, $new_val);

		return 1;
	}

	sub decrement_at {
		my ($self, $row, $col, $val) = @_;

		if ( ! defined $val ) { $val = -1; }

		$self->increment_at($row, $col, $val);

		return 1;
	}
	
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Table::Numeric - Object for storing and operating on a 2D table of numbers


=head1 VERSION

This document describes Table::Numeric version 0.0.1


=head1 SYNOPSIS

    use Table::Numeric;
	
	# create an empty table object
	my $table = Table::Numeric->new();
	
	# see the documentation for Table for the most common functions

	# find the min and max values in the table
	my $min = $table->min();
	my $max = $table->max();
  
  
=head1 DESCRIPTION

This module is an object for storing and opperating on tables (ie 2D matrix)
that are populated by numbers.  See the documentation for the parent object,
Table, for more details.

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
UtilSY
Table


=head1 INCOMPATIBILITIES

None reported.


=head1 METHODS

=over
	
	# Constructor #
	new
	
	# Getters #
	min
	max

	# Setters #
	

	# Others #
	aggregate
	increment_at
	decrement_at

=back

=head1 METHODS DESCRIPTION

=head2 new

	Title: new
	Usage: Table::Numeric->new();
	Function: Initializes an empty Table::Numeric object
	Returns: Table::Numeric
	Args: NA
	Throws: NA
	Comments: Table::Numeric inherits from Table
	See Also: Table
	
=head2 min

	Title: min
	Usage: $obj->min()
	Function: Returns the minimum value in the table
	Returns: int
	Args: NA
	Throws: NA
	Comments: NA
	See Also: NA
	
=head2 max

	Title: max
	Usage: $obj->max()
	Function: Returns the maximum value in the table
	Returns: int
	Args: NA
	Throws: NA
	Comments: NA
	See Also: NA
	
=head2 aggregate

	Title: aggregate
	Usage: $obj->aggregate($grp_aref)
	Function: Aggregates the table based on the defined groups in $grp_aref
	Returns: Table::Numeric
	Args: -grp_aref => array reference of groups to aggregate by
	Throws: MyX::Generic::Undef::Param
			MyX::Generic::Ref::UnsupportedType
		    MyX::Table::BadDim
	Comments: This function aggregates ONLY by rows.  If you want to aggregate
			  by columns you will have to transpose the matrix first and then
			  you can aggregate by rows.  
	See Also: NA

=head2 increment_at

	Title: increment_at
	Usage: $obj->increment_at($row, $col, $val);
	Function: Increments the value at $row,$col by $val
	Returns: 1 on success
	Args: -row => row name
          -col => column name
          [-val] => value by which to increment
	Throws: MyX::Generic::Undef::Param
	Comments: If no $val is provided 1 is used
	See Also: NA

=head2 decrement_at

	Title: decrement_at
	Usage: $obj->decrement_at($row, $col, $val);
	Function: Decrements the value at $row,$col by $val
	Returns: 1 on success
	Args: -row => row name
          -col => column name
          [-val] => value by which to decrement
	Throws: MyX::Generic::Undef::Param
	Comments: If no $val is provided -1 is used
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


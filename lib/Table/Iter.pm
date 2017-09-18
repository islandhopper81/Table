package Table::Iter;

use MyX::Table;
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
use Log::Log4perl::CommandLine qw(:all);
use MyX::Generic;
use version; our $VERSION = qv('0.0.1');

# set up the logging environment
my $logger = get_logger();

{
	# Usage statement
	Readonly my $NEW_USAGE => q{ new({table => })};
	Readonly::Scalar my $SEP => "\t";

	# Attributes #
	my %table_of;
	my %current_row_of;
	my %current_col_of;
	
	# Getters #
	sub get_current_row;
	sub get_current_col;
	sub get_next_value;

	# Setters #
	

	# Others #
	sub has_next_value;
	

	###############
	# Constructor #
	###############
	sub new {
		my ($class, $arg_href) = @_;

		# Croak if calling new on already blessed reference
		croak 'Constructor called on existing object instead of class'
			if ref $class;
			
		# Make sure the required parameters are defined
        if ( any {!defined $_} $arg_href->{table},
            ) {
            MyX::Generic::Undef::Param->throw(
                                              error => 'Undefined parameter value',
                                              usage => $NEW_USAGE,
                                              );
        }

		# Bless a scalar to instantiate an object
		my $new_obj = bless \do{my $anon_scalar}, $class;

		# Set Attributes
		$table_of{ident $new_obj} = $arg_href->{table};
		$current_row_of{ident $new_obj} = 0;
		$current_col_of{ident $new_obj} = -1;
		
		return $new_obj;
	}

	###########
	# Getters #
	###########
	sub get_current_row {
		my ($self) = @_;
		
		return($current_row_of{ident $self});
	}
	
	sub get_current_col {
		my ($self) = @_;
		
		return($current_col_of{ident $self});
	}
	
	sub get_next_value {
		my ($self) = @_;
		
		# NOTE: see the documentation for important instructions on how this 
		# function should be used.
		
		# NOTE: the pointer stays on the last point seen.  At the begining the
		# pointer is not on the table (ie col = -1)
		
		if ( ! $self->has_next_value() ) {
			my $msg = "The table is empty. Call has_next_value to avoid this error";
			MyX::Table::Iter::EmptyTable->throw(
				error => $msg
			);
		}
		
		my $tbl = $table_of{ident $self};
		
		if ( $self->get_current_col() < $tbl->get_col_count() - 1) {
			$current_col_of{ident $self}++;
		}
		else {
			$current_row_of{ident $self}++;
			$current_col_of{ident $self} = 0;
		}
		
		my $val = $tbl->get_value_at_fast($current_row_of{ident $self},
										  $current_col_of{ident $self});
		
		return($val);
	}
	
	###########
	# Setters #
	###########
	
	##########
	# Others #
	##########
	sub has_next_value {
		my ($self) = @_;
		
		my $tbl = $table_of{ident $self};
		
		# the case when the iterator has not yet started
		if ( $self->get_current_col() == -1 ) {
			# check to make sure the table is empty
			if ( $table_of{ident $self}->is_empty() ) {
				return(0); # FALSE
			}
			return(1); # TRUE
		}
		
		if ( $self->get_current_col() < $tbl->get_col_count() - 1) {
			# there is at least one more column to get in the current row
			return (1); # TRUE
		}
		elsif ( $self->get_current_row() < $tbl->get_row_count() - 1) {
			# there is another row
			return(1); # TRUE
		}
		
		return(0); # FALSE
	}
	
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Table::Iter - Object for iterating through a Table's values


=head1 VERSION

This document describes Table::Iter version 0.0.1


=head1 SYNOPSIS

    use Table::Iter;
	
	# create an iterator object
	my $tbl_iter = Table::Iter->new({table => $tbl_obj});
	
	# iterate over the values
	while ( my $val = $tbl_iter->get_next_value() ) {
		print $val, "\n";
	}
  
  
=head1 DESCRIPTION

This module is an object for iterating over the values in a table.  To iterate
over a table object use code that looks something like this:

my $tbl_iter = Table::Iter->new({table => $tbl});

while ( $tbl_iter->has_next_value() ) {
	my $val = $tbl_iter->get_next_val();
}

do NOT put the get_next_val in the while loop.  Zero values will cause your
iteration to terminate prematurely is you do that because zero is also evaluated
by perl as FALSE.

Also, if the Table that you are interating over has been sorted by row or
column, the iteration will still happen in the order of the unsorted Table.

=head1 CONFIGURATION AND ENVIRONMENT
  
Table requires no configuration files or environment variables.


=head1 DEPENDENCIES

MyX::Table
Table
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
	sub get_current_row;
	sub get_current_col;
	sub get_next_value;
	
	# Setters #
	
	# Others #
	sub has_next_value;
	
	
=back

=head1 METHODS DESCRIPTION

=head2 new

	Title: new
	Usage: Table::Iter->new({table => $tbl_obj});
	Function: Initializes Table::Iter object
	Returns: Table::Iter
	Args: -tbl_obj => a Table object
	Throws: NA
	Comments: NA
	See Also: NA
	
=head2 get_current_row

	Title: get_current_row
	Usage: $tbl_iter->get_current_row()
	Function: Returns the current row index of the iterator
	Returns: int
	Args: NA
	Throws: NA
	Comments: NA
	See Also: NA
	
=head2 get_current_col

	Title: get_current_col
	Usage: $tbl_iter->get_current_col()
	Function: Returns the current col index of the iterator
	Returns: int
	Args: NA
	Throws: NA
	Comments: NA
	See Also: NA
	
=head2 get_next_value

	Title: get_next_value
	Usage: $tbl_iter->get_next_value()
	Function: Returns the next value in the Table
	Returns: whatever type is in the table
	Args: NA
	Throws: MyX::Table::Iter::EmptyTable
	Comments: This iterates by rows.  In other words the algorithm looks like:
	
				foreach my $r ( rows )
					forach my $c ( cols )
						return (r,c)
							
			  Note that when the iterator is created it's pointer starts off the
			  beginning of the table (ie at col -1).  To avoid getting a
			  MyX::Table::Iter::EmptyTable error you should use the function
			  has_next_value before getting the next value.  So when you iterate
			  over the table your code should look something like this:
			  
				while ( $tbl_iter->has_next_value() ) {
					my $val = $tbl_iter->get_next_value();
				}
				
			  do NOT put the get_next_value in the while loop.  Zero values will
			  cause your iteration to terminate prematurely is you do that
			  because zero is also evaluated by perl as FALSE.
			  
	See Also: NA
	
=head2 has_next_value

	Title: has_next_value
	Usage: $tbl_iter->has_next_value()
	Function: Returns true if there is another value to get
	Returns: bool (ie 0 | 1)
	Args: NA
	Throws: NA
	Comments: See get_next_value for important comments about how to use this
			  function.
	See Also: get_next_value()


=head1 BUGS AND LIMITATIONS


No bugs have been reported.

Please report any bugs or feature requests to
C<bug-table@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 TO DO

NA

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


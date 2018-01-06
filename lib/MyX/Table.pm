package MyX::Table;

use version; our $VERSION = qv('0.0.2');

use Exception::Class (
    'MyX::Table' => {
    },
    
    'MyX::Table::BadDim' => {
        isa => 'MyX::Table',
        fields => ['dim'],
    },
    
    'MyX::Table::NamesNotUniq' => {
        isa => 'MyX::Table',
        fields => ['dim'],
    },
    
    'MyX::Table::Row' => {
        isa => 'MyX::Table',
    },
    
    'MyX::Table::Row::UndefName' => {
        isa => 'MyX::Table::Row',
        fields => ['name']
    },
    
    'MyX::Table::Col' => {
        isa => 'MyX::Table',
    },
    
    'MyX::Table::Col::UndefName' => {
        isa => 'MyX::Table::Col',
        fields => ['name']
    },
    
    'MyX::Table::Row::NameInTable' => {
        isa => 'MyX::Table::Row',
        fields => ['name']
    },
    
    'MyX::Table::Col::NameInTable' => {
        isa => 'MyX::Table::Col',
        fields => ['name']
    },
    
    'MyX::Table::Merge' => {
        isa => 'MyX::Table',
    },
    
    'MyX::Table::Order' => {
        isa => 'MyX::Table',
    },
    
    'MyX::Table::Order::Row' => {
        isa => 'MyX::Table::Order',
    },
    
    'MyX::Table::Order::Col' => {
        isa => 'MyX::Table::Order',
    },
    
    'MyX::Table::Order::Row::NamesNotEquiv' => {
        isa => 'MyX::Table::Order',
    },
    
    'MyX::Table::Order::Col::NamesNotEquiv' => {
        isa => 'MyX::Table::Order',
    },
    
    'MyX::Table::Bind' => {
        isa => 'MyX::Table',
    },
    
    'MyX::Table::Bind::NamesNotEquiv' => {
        isa => 'MyX::Table::Bind',
    },
    
);

1;
__END__


#######
# POD #
#######
=head1 NAME

MyX::Table - A hierarchy of exceptions that can be used in Table.pm

=head1 VERSION

This documentation refers to MyX::Table version 0.0.2.

=head1 Included Modules

    Exception::Class

=head1 Inherit

    NA

=head1 SYNOPSIS

    # Throw a MyX::Table::BadDim exception
    use MyX::Table;
    if ( ... ) {   # Some code looking for an error
        MyX::Table::BadDim->throw(
                            error => 'An execption'
                            );
    }
    
    # In caller catch the MyX::Table::Iter exception
    eval { ... };
    if ( my $e = MyX::Table::BadDim->caught() ) {
        # Do something to handle the exception like print an error message
        print $e->error(), " via package ", $e->package(), " at ", $e->file,
            " line ", $e->line();
    }
    

=head1 DESCRIPTION

MyX::Table holds a hierarchy of exception classes that can be used in Table
objects

For more information what can be done when throwing and catching an exception
see Exception::Class and Exception::Class::Base.

=head1 CLASSES

=over

    MyX::Table
    MyX::Table::BadDim
    MyX::Table::NamesNotUniq
    MyX::Table::Row
    MyX::Table::Row::UndefName
    MyX::Table::Col
    MyX::Table::Col::UndefName
    MyX::Table::Row::NameInTable
    MyX::Table::Col::NameInTable
    MyX::Table::Merge
    MyX::Table::Order
    MyX::Table::Order::Row
    MyX::Table::Order::Col
    MyX::Table::Order::Row::NamesNotEquiv
    MyX::Table::Order::Col::NamesNotEquiv
    MyX::Table::Bind
    MyX::Table::Bind::NamesNotEquiv
    
    
=back

=head1 CLASSES DESCRIPTION

=head2 MyX::Table
    
    Title: MyX::Table
    Throw Usage: MyX::Table->throw(
                    error => 'Any error message'
                );
    Catch Usage: if ( my $e = MyX::Table->caught() ) { ... }
    Function: Throw/Catch a MyX::Table exception
    Fields: error => an error message
    Inherits: NA
    Comments: NA
    See Also: NA

=head2 MyX::Table::BadDim

    Title: MyX::Table::BadDim
    Throw Usage: MyX::Table::BadDim->throw(
                    dim => $dim,
                );
    Catch Usage: if ( my $e = MyX::Table::BadDim->caught() ) { ... }
    Function: Throw/Catch a MyX::Table::BadDim exception when the dimensions do
              not match.
    Fields: dim => dimensions string
    Inherits: MyX::Table
    Comments: NA
    See Also: NA
    
=head2 MyX::Table::NamesNotUniq

    Title: MyX::Table::NamesNotUniq
    Throw Usage: MyX::Table::NamesNotUniq->throw();
    Catch Usage: if ( my $e = MyX::Table::NamesNotUniq->caught() ) { ... }
    Function: Throw/Catch a MyX::Table::NamesNotUniq exception when the names in
              the rows or cols are not unique
    Fields: dim => dimension where the names are not unique (ie row | col)
    Inherits: MyX::Table
    Comments: NA
    See Also: NA
    
=head2 MyX::Table::Row

    Title: MyX::Table::Row
    Throw Usage: MyX::Table::Row->throw();
    Catch Usage: if ( my $e = MyX::Table::Row->caught() ) { ... }
    Function: Throw/Catch a MyX::Table::Row exception when an error with a row
              is encountered.
    Fields: NA
    Inherits: MyX::Table
    Comments: NA
    See Also: NA
    
=head2 MyX::Table::Row::UndefName

    Title: MyX::Table::Row::UndefName
    Throw Usage: MyX::Table::Row::UndefName->throw(
                    name => $row_name
                );
    Catch Usage: if ( my $e = MyX::Table::Row::UndefName->caught() ) { ... }
    Function: Throw/Catch a MyX::Table::Row::UndefName exception when an
              exception is encounted with an undefined row name
    Fields: name => name of the row
    Inherits: MyX::Table::Row
    Comments: NA
    See Also: NA
    
=head2 MyX::Table::Col

    Title: MyX::Table::Col
    Throw Usage: MyX::Table::Col->throw();
    Catch Usage: if ( my $e = MyX::Table::Col->caught() ) { ... }
    Function: Throw/Catch a MyX::Table::Col exception when an error with a col
              is encountered.
    Fields: NA
    Inherits: MyX::Table
    Comments: NA
    See Also: NA
    
=head2 MyX::Table::Col::UndefName

    Title: MyX::Table::Col::UndefName
    Throw Usage: MyX::Table::Col::UndefName->throw(
                    name => $col_name
                );
    Catch Usage: if ( my $e = MyX::Table::Col::UndefName->caught() ) { ... }
    Function: Throw/Catch a MyX::Table::Col::UndefName exception when an
              exception is encounted with an undefined column name
    Fields: name => name of the column
    Inherits: MyX::Table::Col
    Comments: NA
    See Also: NA
    
=head2 MyX::Table::Row::NameInTable

    Title: MyX::Table::Row::NameInTable
    Throw Usage: MyX::Table::Row::NameInTable->throw(
                    name => $row_name
                );
    Catch Usage: if ( my $e = MyX::Table::Row::NameInTable->caught() ) { ... }
    Function: Throw/Catch a MyX::Table::Row::NameInTable exception when
              a row is already in the table.  There cannot be duplicate row
              names
    Fields: name => name of the row
    Inherits: MyX::Table::Row
    Comments: NA
    See Also: NA
    
=head2 MyX::Table::Col::NameInTable

    Title: MyX::Table::Col::NameInTable
    Throw Usage: MyX::Table::Col::NameInTable->throw(
                    name => $col_name
                );
    Catch Usage: if ( my $e = MyX::Table::Col::NameInTable->caught() ) { ... }
    Function: Throw/Catch a MyX::Table::Col::NameInTable exception when
              a col is already in the table.  There cannot be duplicate column
              names
    Fields: name => name of the col
    Inherits: MyX::Table::Col
    Comments: NA
    See Also: NA
    
=head2 MyX::Table::Merge

    Title: MyX::Table::Merge
    Throw Usage: MyX::Table::Merge->throw();
    Catch Usage: if ( my $e = MyX::Table::Merge->caught() ) { ... }
    Function: Throw/Catch a MyX::Table::Merge exception
              when soemthing goes wrong in a merge operation
    Fields: NA
    Inherits: MyX::Table
    Comments: NA
    See Also: NA
    
=head2 MyX::Table::Order

    Title: MyX::Table::Order
    Throw Usage: MyX::Table::Order->throw();
    Catch Usage: if ( my $e = MyX::Table::Order->caught() ) { ... }
    Function: Throw/Catch a MyX::Table::Order exception
              when something goes wrong while ordering the table
    Fields: NA
    Inherits: MyX::Table
    Comments: NA
    See Also: NA
    
=head2 MyX::Table::Order::Row

    Title: MyX::Table::Order::Row
    Throw Usage: MyX::Table::Order::Row->throw();
    Catch Usage: if ( my $e = MyX::Table::Order::Row->caught() ) { ... }
    Function: Throw/Catch a MyX::Table::Order::Row exception
              when something goes wrong while ordering the table rows
    Fields: NA
    Inherits: MyX::Table::Order
    Comments: NA
    See Also: NA
    
=head2 MyX::Table::Order::Col

    Title: MyX::Table::Order::Col
    Throw Usage: MyX::Table::Order::Col->throw();
    Catch Usage: if ( my $e = MyX::Table::Order::Col->caught() ) { ... }
    Function: Throw/Catch a MyX::Table::Order::Col exception
              when something goes wrong while ordering the table cols
    Fields: NA
    Inherits: MyX::Table::Order
    Comments: NA
    See Also: NA
    
=head2 MyX::Table::Order::Col::NamesNotEquiv

    Title: MyX::Table::Order::Col::NamesNotEquiv
    Throw Usage: MyX::Table::Order::Col::NamesNotEquiv->throw();
    Catch Usage: if ( my $e = MyX::Table::Order::Col::NamesNotEquiv->caught() ) { ... }
    Function: Throw/Catch a MyX::Table::Order::Col::NamesNotEquiv exception
              when the col names are not perfectly equivelant between the table
              and given ordering
    Fields: NA
    Inherits: MyX::Table::Order::Col
    Comments: NA
    See Also: NA
    
=head2 MyX::Table::Order::Row::NamesNotEquiv

    Title: MyX::Table::Order::Row::NamesNotEquiv
    Throw Usage: MyX::Table::Order::Row::NamesNotEquiv->throw();
    Catch Usage: if ( my $e = MyX::Table::Order::Row::NamesNotEquiv->caught() ) { ... }
    Function: Throw/Catch a MyX::Table::Order::Row::NamesNotEquiv exception
              when the row names are not perfectly equivelant between the table
              and given ordering
    Fields: NA
    Inherits: MyX::Table::Order::Row
    Comments: NA
    See Also: NA

=head2 MyX::Table::Bind

    Title: MyX::Table::Bind
    Throw Usage: MyX::Table::Bind->throw();
    Catch Usage: if ( my $e = MyX::Table::Bind->caught() ) { ... }
    Function: Throw/Catch a MyX::Table::Bind exception
              when something goes wrong while binding two tables together
    Fields: NA
    Inherits: MyX::Table
    Comments: NA
    See Also: NA
    
=head2 MyX::Table::Bind::NamesNotEquiv

    Title: MyX::Table::Bind::NamesNotEquiv
    Throw Usage: MyX::Table::Bind::NamesNotEquiv->throw();
    Catch Usage: if ( my $e = MyX::Table::Bind::NamesNotEquiv->caught() ) { ... }
    Function: Throw/Catch a MyX::Table::Bind::NamesNotEquiv exception
              when the row or col names of two tables that are being bound
              together are not equivelant
    Fields: NA
    Inherits: MyX::Table::Bind
    Comments: NA
    See Also: NA


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to the author


=head1 AUTHOR

Scott Yourstone  C<< <scott.yourstone81@gmail.com> >>


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


=cut


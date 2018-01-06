package MyX::Table::Iter;

use version; our $VERSION = qv('0.0.2');

use Exception::Class (
    'MyX::Table::Iter' => {
    },
    
    'MyX::Table::Iter::EmptyTable' => {
        isa => 'MyX::Table::Iter',
    },
    
);

1;
__END__


#######
# POD #
#######
=head1 NAME

MyX::Table::Iter - A hierarchy of exceptions that can be used in Table::Iter.pm

=head1 VERSION

This documentation refers to MyX::Table::Iter version 0.0.2.

=head1 Included Modules

    Exception::Class

=head1 Inherit

    NA

=head1 SYNOPSIS

    # Throw a MyX::Table::Iter::EmptyTable exception
    use MyX::Table::Iter;
    if ( ... ) {   # Some code looking for an error
        MyX::Table::Iter::EmptyTable->throw(
            error => 'An execption message'
        );
    }
    
    # In caller catch the MyX::Table::Iter exception
    eval { ... };
    if ( my $e = MyX::Table::Iter::EmptyTable->caught() ) {
        # Do something to handle the exception like print an error message
        print $e->error(), " via package ", $e->package(), " at ", $e->file,
            " line ", $e->line();
    }
    

=head1 DESCRIPTION

MyX::Table::Iters holds a hierarchy of exception classes that can be used in
Table::Iter objects

For more information what can be done when throwing and catching an exception
see Exception::Class and Exception::Class::Base.

=head1 CLASSES

=over

    MyX::Table::Iter
    MyX::Table::Iter::EmptyTable
    
=back

=head1 CLASSES DESCRIPTION

=head2 MyX::Table::Iter
    
    Title: MyX::Table::Iter
    Throw Usage: MyX::Table::Iter->throw(
                    error => 'Any error message'
                );
    Catch Usage: if ( my $e = MyX::Table::Iter->caught() ) { ... }
    Function: Throw/Catch a MyX::Table::Iter exception
    Fields: error => an error message
    Inherits: NA
    Comments: NA
    See Also: NA
    
=head2 MyX::Table::Iter::EmptyTable
    
    Title: MyX::Table::Iter::EmptyTable
    Throw Usage: MyX::Table::Iter::EmptyTable->throw(
                    error => 'Any error message'
                );
    Catch Usage: if ( my $e = MyX::Table::Iter::EmptyTable->caught() ) { ... }
    Function: Throw/Catch a MyX::Table::Iter::EmptyTable exception
    Fields: error => an error message
    Inherits: NA
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


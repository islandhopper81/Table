#!/usr/bin/env perl

# Used for benchmarking and testing table-like objects

use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;
use Carp;
use Readonly;
use version; our $VERSION = qv('0.0.1');
use Log::Log4perl qw(:easy);
use Log::Log4perl::CommandLine qw(:all);
use UtilSY qw(:all);
use Benchmark qw(cmpthese timethese);
#use Memory::Usage;
use Memchmark qw(cmpthese);

# table-like objects
use Table;
use Data::Table;
use Text::Table;

# Subroutines #
sub check_params;

# Variables #
my ($tbl_f, $help, $man);

my $options_okay = GetOptions (
    "tbl_f|t:s" => \$tbl_f,
    "help|h" => \$help,                  # flag
    "man" => \$man,                     # flag (print full man page)
);

# set up the logging environment
my $logger = get_logger();

# check for input errors
if ( $help ) { pod2usage(-verbose => 0) }
if ( $man ) { pod2usage(-verbose => 3) }
check_params();


########
# MAIN #
########
$logger->info("Begin benchmarking");

my $skip_time = 1;

# time the loading feature
if ( !$skip_time ) {
	$logger->info("Begin time benchmarking");
	timethese( 100, {
		'Data::Table'	=> sub { _load_data_table($tbl_f) },
		'Text::Table'	=> sub { _load_text_table($tbl_f) },
		'Table' 		=> sub { _load_table($tbl_f) }
	});
}
else {
	$logger->info("skipping time benchmark");
}

# measure memory usage
$logger->info("Begin memory benchmarking");
cmpthese(
	'Data::Table'	=> sub { _load_data_table($tbl_f) },
	'Text::Table'	=> sub { _load_text_table($tbl_f) },
	'Table' 		=> sub { _load_table($tbl_f) }
);


########
# Subs #
########
sub _load_data_table {
	my ($tbl_f) = @_;

	my $t = Data::Table::fromCSV($tbl_f);

	return($t);
}

sub _load_table {
	my ($tbl_f) = @_;

	my $t = Table->new();
	$t->load_from_file({
		file => $tbl_f,
		sep => ",",
		has_row_names => "F"
	});

	return($t);
}

sub _load_text_table {
	my ($tbl_f) = @_;

	open my $TBL, "<", $tbl_f or
		$logger->logdie("Cannot open table file: $tbl_f");

	my $headers;  # will be an aref
	my $first = 1;
	my @lines = ();  # this will be a 2d array
	foreach my $line ( <$TBL> ) {
		chomp $line;
		my @vals = split(/,/, $line);

		if ( $first == 1 ) {
			$headers = \@vals;
		}
		else{
			push @lines, \@vals;
		}
	}

	close($TBL);

	# create the table
	my $t = Data::Table->new(\@lines, $headers, 0);

	return($t);
}

sub check_params {
	# check for required variables
	if ( ! defined $tbl_f) { 
		pod2usage(-message => "ERROR: required --tbl_f not defined\n\n",
					-exitval => 2); 
	}

	# make sure required files are non-empty
	if ( defined $tbl_f and ! -e $tbl_f ) { 
		pod2usage(-message => "ERROR: --tbl_f $tbl_f is an empty file\n\n",
					-exitval => 2);
	}

	# make sure required directories exist
	#if ( ! -d $dir ) { 
	#	pod2usage(-message => "ERROR: --dir is not a directory\n\n",
	#				-exitval => 2); 
	#}
	
	return 1;
}


__END__

# POD

=head1 NAME

[NAME].pl - [DESCRIPTION]


=head1 VERSION

This documentation refers to version 0.0.1


=head1 SYNOPSIS

    [NAME].pl
        -f my_file.txt
        -v 10
        
        [--help]
        [--man]
        [--debug]
        [--verbose]
        [--quiet]
        [--logfile logfile.log]

    --file | -f     Path to an input file
    --var | -v      Path to an input variable
    --help | -h     Prints USAGE statement
    --man           Prints the man page
    --debug	        Prints Log4perl DEBUG+ messages
    --verbose       Prints Log4perl INFO+ messages
    --quiet	        Suppress printing ERROR+ Log4perl messages
    --logfile       File to save Log4perl messages


=head1 ARGUMENTS
    
=head2 --file | -f

Path to an input file
    
=head2 --var | -v

Path to an input variable   
 
=head2 [--help | -h]
    
An optional parameter to print a usage statement.

=head2 [--man]

An optional parameter to print he entire man page (i.e. all documentation)

=head2 [--debug]

Prints Log4perl DEBUG+ messages.  The plus here means it prints DEBUG
level and greater messages.

=head2 [--verbose]

Prints Log4perl INFO+ messages.  The plus here means it prints INFO level
and greater messages.

=head2 [--quiet]

Suppresses print ERROR+ Log4perl messages.  The plus here means it suppresses
ERROR level and greater messages that are automatically printed.

=head2 [--logfile]

File to save Log4perl messages.  Note that messages will also be printed to
STDERR.
    

=head1 DESCRIPTION

[FULL DESCRIPTION]

=head1 CONFIGURATION AND ENVIRONMENT
    
No special configurations or environment variables needed
    
    
=head1 DEPENDANCIES

version
Getopt::Long
Pod::Usage
Carp
Readonly
version
Log::Log4perl qw(:easy)
Log::Log4perl::CommandLine qw(:all)
UtilSY qw(:all)

=head1 AUTHOR

Scott Yourstone     scott.yourstone@q2labsolutions.com
    
=cut

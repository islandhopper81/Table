use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Table',
    license             => 'artistic2',
    dist_author         => 'Scott Yourstone <scott.yourstone.com>',
    dist_version_from   => 'lib/Table.pm',
    requires => {
		'Class::Std::Utils' => 0,
		'Array::Utils' => 0,
		'Scalar::Util' => 0,
		'List::MoreUtils' => 0,
		'List::Compare' => 0,
		'Log::Log4perl' => 0,
		'Log::Log4perl::CommandLine' => 0,
        'Test::More' => 0,
        'version'    => 0,
    },
    add_to_cleanup      => [ 'Table-*' ],
    recursive_test_files => 1,
);

$builder->create_build_script();

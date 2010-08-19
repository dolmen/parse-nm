#!/usr/bin/env perl
use utf8;  # vim:set ts=4 sw=4 sts=4:

use strict;
use warnings;

use Module::Build;

my $class = 'Module::Build';

if (-d '.git') {
	$class = $class->subclass(
		class => 'My::Builder',
		code => q{
			sub ACTION_tag {
                my ($self) = @_;
				my $v = $self->dist_version;
				system(qw(git tag -a -m), "CPAN release $v", "release-$v")
					or die "Git tagging failed.";
			}
		},
	);
}

my $builder = $class->new(
	module_name => 'Parse::nm',
	dist_author => 'Olivier Mengué <dolmen@cpan.org>',
	license     => 'perl',
	meta_add    => {
		resources => {
			homepage => 'http://github.com/dolmen/parse-nm',
			repository => 'http://github.com/dolmen/parse-nm.git',
			bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Parse-nm',
		},
	},
	requires    => {
		'Regexp::Assemble' => '0.34',
		'String::ShellQuote' => '1.03',
	},
	build_requires => {
		'Module::Build' => '0.3607',
		'Test::More' => '0.94',
		'File::Spec' => 0,
	},
    build_recommends => {
        'ExtUtils::CBuilder' => '0.27',
    },
);
$builder->add_to_cleanup('MANIFEST.bak');
$builder->create_build_script();

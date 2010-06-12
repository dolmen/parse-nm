# Full test:
# - compile t/t.c into an object file into t.o
# - test Parse::nm->run() against t.o

use strict;
use warnings;
use Config;
use File::Spec;
use Test::More;
use Parse::nm;

BEGIN {
    eval {
	require ExtUtils::CBuilder;
    };
    if ($@) {
	plan skip_all => 'ExtUtils::CBuilder not installed';
    } else {
	import ExtUtils::CBuilder;
    }
}

my $src = File::Spec->catfile('t', 't.c');
my $obj = eval {
    ExtUtils::CBuilder->new(quiet => 1)->compile(source => $src);
};
plan skip_all => "Compile '$src' failed" if $@ || !defined $obj || !-f $obj;

END {
    if (defined $obj && -f $obj) {
        diag "Remove '$obj'";
        unlink $obj;
    }
}


plan tests => 8;

my $count = 0;

Parse::nm->run(
    files => $obj,
    filters => [
    {
	name => qr/TestFunc/,
	type => qr/[A-Z]/,
	action => sub {
	    pass "action1 called";
	    is ++$count, 1;
	    is $_[0], "TestFunc", "arg0";
	    is $_[1], "T", "arg1";
	}
    },
    {
	name => qr/TestVar/,
	#type => qr/[A-Z]/,
	action => sub {
	    pass "action2 called";
	    is ++$count, 2;
	    is $_[0], "TestVar", "arg0";
	    like $_[1], qr/^[GD]$/, 'arg1';
	}
    }
]);

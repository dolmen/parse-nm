use strict;
use warnings;
use Config;
use File::Spec;
use Test::More tests => 9;
use Parse::nm;

my $src = File::Spec->catfile('t', 't.c');
my $obj = "t$Config{obj_ext}";

END {
    if (-f $obj) {
        diag "Remove '$obj'";
        unlink $obj;
    }
}

diag "Compile '$src' to '$obj'...";
# TODO Use ExtUtils::CBuilder if available
my $exec = qx/$Config{cc} $Config{ccflags} -c $src/;

SKIP: {
    skip 'Compile failed.' => 9 unless -f $obj;

    pass "$obj exists";

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
                is $_[1], "C", "arg1";
            }
        }
    ]);
}

#!perl -T

use warnings;
use strict;

use Test::More tests => 1;

BEGIN {
    use_ok( 'Parse::nm' );
}

diag( "Testing Parse::nm ".Parse::nm->VERSION.", Perl $], $^X" );

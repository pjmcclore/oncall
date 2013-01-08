#!/usr/bin/perl
#

use 5.010;
use lib 'lib';
use OnCall;

my $oc = OnCall->new(
    token => 'da860dcc8ab87f28a50282bbe800136d',
    debug => 1,
);
say $oc->tell({
        message => "Problem in test run",
        test    => 'nok - bla test',
        prio    => 2
});

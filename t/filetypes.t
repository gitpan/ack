#!perl -Tw

use warnings;
use strict;

use Test::More tests => 8;

BEGIN {
    use_ok( 'App::Ack' );
}

is_deeply( [sort(filetypes( "foo.pod" ))], [qw( parrot perl )], 'foo.pod can be multiple things' );
is_deeply( [filetypes( "Bongo.pm" )], [qw( perl )], 'Bongo.pm' );
is_deeply( [filetypes( "Makefile.PL" )], [qw( perl )], 'Makefile.PL' );
is_deeply( [filetypes( "Unknown.wango" )], [], 'Unknown' );

ok(  is_filetype( "foo.pod", "perl" ), 'foo.pod can be perl' );
ok(  is_filetype( "foo.pod", "parrot" ), 'foo.pod can be parrot' );
ok( !is_filetype( "foo.pod", "ruby" ), 'foo.pod cannot be ruby' );


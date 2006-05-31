#!perl -Tw

use warnings;
use strict;

use Test::More tests => 3;

BEGIN {
    use_ok( 'App::Ack' );
}

sub is_perl {
    my $file = shift;

    for my $type ( filetypes( $file ) ) {
        return 1 if $type eq "perl";
    }
    return;
}

PERL_FILES: {
    my @files;
    my $iter = interesting_files( \&is_perl, 1, 't/swamp' );

    while ( my $file = $iter->() ) {
        push( @files, $file );
    }

    is_deeply( [sort @files], [sort qw(
        t/swamp/Makefile.PL
        t/swamp/perl.pl
        t/swamp/perl.pm
        t/swamp/perl.pod
        t/swamp/perl-test.t
        t/swamp/perl-without-extension
    )] );
}

sub is_parrot {
    my $file = shift;

    for my $type ( filetypes( $file ) ) {
        return 1 if $type eq "parrot";
    }
    return;
}

PARROT_FILES: {
    my @files;
    my $iter = interesting_files( \&is_parrot, 1, 't' );

    while ( my $file = $iter->() ) {
        push( @files, $file );
    }

    is_deeply( [sort @files], [sort qw(
        t/swamp/parrot.pir
        t/swamp/perl.pod
    )] );
}

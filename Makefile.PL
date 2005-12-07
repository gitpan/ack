use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'ack',
    AUTHOR              => 'Andy Lester <andy@petdance.com>',
    ABSTRACT            => 'A grep-like program specifically for large source trees',
    VERSION_FROM        => 'Ack.pm',
    PM                  => { "Ack.pm" => '$(INST_LIBDIR)/App/Ack.pm' },
    MAN3PODS            => {}, # App::Ack's docs aren't useful
    EXE_FILES           => [ 'ack' ],
    PREREQ_PM => {
        'File::Find' => 0,
        'Term::ANSIColor' => 0,
        'Getopt::Long' => 0,
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'ack-*' },
);

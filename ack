#!/usr/local/bin/perl -w

use strict;

our $is_windows;
BEGIN {
    $is_windows = ($^O =~ /MSWin32/);
}

BEGIN {
    eval { use Term::ANSIColor } unless $is_windows;
}

use App::Ack qw( filetypes interesting_files );
use Getopt::Long;

our $is_tty =       -t STDOUT;
our $opt_group =    $is_tty;
our $opt_color =    $is_tty && !$is_windows;
our $opt_all =      0;
our $opt_help =     0;
our %lang;

our @languages_supported = qw( cc javascript parrot perl php python ruby shell sql );

my %options = (
    h           => \( our $opt_h = 0 ),
    i           => \( our $opt_i = 0 ),
    l           => \( our $opt_l = 0 ),
    "m=i"       => \( our $opt_m = 0 ),
    n           => \( our $opt_n = 0 ),
    o           => \( our $opt_o = 0 ),
    v           => \( our $opt_v = 0 ),
    w           => \( our $opt_w = 0 ),
    f           => \( our $opt_f = 0 ),
    "all!"      => \$opt_all,
    a           => \$opt_all,
    "group!"    => \$opt_group,
    "color!"    => \$opt_color,
    "help"      => \$opt_help,
    "version"   => sub { print "ack $App::Ack::VERSION\n" and exit 1; },
);
for my $i ( @languages_supported ) {
    $options{ "$i!" } = \$lang{ $i };
}
$options{ "js!" } = \$lang{ javascript };

# Stick any default switches at the beginning, so they can be overridden
# by the command line switches.
unshift @ARGV, split( " ", $ENV{ACK_SWITCHES} ) if defined $ENV{ACK_SWITCHES};

Getopt::Long::Configure( "bundling" );
GetOptions( %options ) or $opt_help = 1;

my $languages_supported_set =   grep { defined $lang{$_} && ($lang{$_} == 1) } @languages_supported;
my $languages_supported_unset = grep { defined $lang{$_} && ($lang{$_} == 0) } @languages_supported;

# If anyone says --noperl, we assume all other languages must be on.
if ( !$languages_supported_set ) {
    for ( keys %lang ) {
        $lang{$_} = 1 unless defined $lang{$_};
    }
}

if ( $opt_help || (!@ARGV && !$opt_f) ) {
    print <DATA>;  # Show usage
    exit 1;
}

my $re;

if ( !$opt_f ) {
    $re = shift or die "No regex specified\n";

    if ( $opt_w ) {
        $re = $opt_i ? qr/\b$re\b/i : qr/\b$re\b/;
    }
    else {
        $re = $opt_i ? qr/$re/i : qr/$re/;
    }
}

my @what = @ARGV ? @ARGV : ".";

sub is_interesting {
    my $file = shift;

    return if $file =~ /~$/;
    return 1 if $opt_all;

    for my $type ( filetypes( $file ) ) {
        return 1 if $lang{$type};
    }
    return;
}

my $iter = interesting_files( \&is_interesting, !$opt_n, @what );

while ( my $file = $iter->() ) {
    if ( $opt_f ) {
        print "$file\n";
    }
    else {
        search( $file, $re );
    }
}


sub search {
    my $filename = shift;
    my $regex = shift;

    my $nmatches = 0;

    my $fh;
    if ( !open( $fh, "<", $filename ) ) {
        warn "ack: $filename: $!\n";
        return;
    }

    local $_;
    while (<$fh>) {
        if ( /$re/ ) {
            ++$nmatches;

            if ( $opt_l ) {
                print "$filename\n";
                last;
            }

            # No point in still searching if we know we want negative match
            last if $opt_v;

            my $out;

            if ( $opt_o ) {
                $out = "$&\n";
            }
            else {
                $out = $_;
                $out =~ s/($re)/colored($1,"black on_yellow")/eg if $opt_color;
            }

            if ( $opt_h ) {
                print $out;
            }
            else {
                my $colorname = $opt_color ? colored( $filename, "bold green" ) : $filename;
                if ( $opt_group ) {
                    print "$colorname\n" if $nmatches == 1;
                    print "$.:$out";
                }
                else {
                    print "$colorname:$.:$out";
                }
            }

            last if $opt_m && ( $nmatches >= $opt_m );
        } # match
    } # while

    print "$filename\n" if $opt_v && !$nmatches;
    print "\n" if $nmatches && ($opt_group && !$opt_l);

    close $fh;
}


=head1 NAME

ack - grep-like text finder for large trees of text

=head1 DESCRIPTION

F<ack> is a F<grep>-like program with optimizations for searching through
large trees of source code.

Key improvements include:

=over 4

=item * Defaults to only searching program source code

=item * Defaults to recursively searching directories

=item * Ignores F<blib> directories.

=item * Ignores source code control directories, like F<CVS>, F<.svn> and F<_darcs>.

=item * Uses Perl regular expressions

=item * Highlights matched text

=back

=head1 TODO

=over 4

=item * Search through standard input if no files specified

=item * Add a --[no]comment option to grep inside or exclude comments.

=back

=cut

1;

__DATA__
Usage: ack [OPTION]... PATTERN [FILES]
Search for PATTERN in each source file in the tree from cwd on down.
If [FILES] is specified, then only those files/directories are checked.
Default switches may be specified in ACK_SWITCHES environment variable.

Example: ack -i select

Searching:
    -i                ignore case distinctions
    -v                invert match: select non-matching lines
    -w                force PATTERN to match only whole words

Search output:
    -l                only print filenames containing matches
    -o                show only the part of a line matching PATTERN
    -m=NUM            stop after NUM matches
    -h                don't print filenames
    --[no]group       print a blank line between each file's matches
                      (default: on unless output is redirected)
    --[no]color       highlight the matching text (default: on unless
                      output is redirected, or on Windows)

File finding:
    -f                only print the files found, without searching.
                      The PATTERN must not be specified.

File selection:
    -n                No descending into subdirectories
    -a, --all         All files, regardless of extension
                      (but still skips RCS, CVS, .svn, _darcs and blib dirs)
    --[no]cc          .c and .h
    --[no]javascript  .js
    --[no]js          same as --[no]javascript
    --[no]parrot      .pir, .pasm, .pmc, .ops, .pod
    --[no]perl        .pl, .pm, .pod, .t, .tt and .ttml
    --[no]php         .html, .php, and .phpt
    --[no]python      .py
    --[no]ruby        .rb
    --[no]shell       shell scripts
    --[no]sql         .sql and .ctl files

Miscellaneous:
    --help            this help
    --version         display version

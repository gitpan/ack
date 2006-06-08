#!/usr/local/bin/perl -w

use strict;

our $is_windows;
BEGIN {
    $is_windows = ($^O =~ /MSWin32/);
}

BEGIN {
    eval { use Term::ANSIColor } unless $is_windows;
}

use App::Ack qw( filetypes filetypes_supported interesting_files _thpppt );
use Getopt::Long;

our %opt;
our %lang;

our $is_tty =  -t STDOUT;
$opt{group} =   $is_tty;
$opt{color} =   $is_tty && !$is_windows;
$opt{all} =     0;
$opt{help} =    0;
$opt{m} =       0;

my %options = (
    a           => \$opt{all},
    "all!"      => \$opt{all},
    f           => \$opt{f},
    h           => \$opt{h},
    H           => \$opt{H},
    i           => \$opt{i},
    l           => \$opt{l},
    "m=i"       => \$opt{m},
    n           => \$opt{n},
    o           => \$opt{o},
    v           => \$opt{v},
    w           => \$opt{w},

    "group!"    => \$opt{group},
    "color!"    => \$opt{color},
    "help"      => \$opt{help},
    "version"   => sub { print "ack $App::Ack::VERSION\n" and exit 1; },
);

for my $bp qw( b p ) {
    for my $n ( 1..6 ) {
        $options{"th".${bp}x$n."t"} = \&_thpppt;
    }
}

my @filetypes_supported = filetypes_supported();
for my $i ( @filetypes_supported ) {
    $options{ "$i!" } = \$lang{ $i };
}
$options{ "js!" } = \$lang{ javascript };

# Stick any default switches at the beginning, so they can be overridden
# by the command line switches.
unshift @ARGV, split( " ", $ENV{ACK_SWITCHES} ) if defined $ENV{ACK_SWITCHES};
Getopt::Long::Configure( "bundling" );
GetOptions( %options ) or die "ack --help for options.\n";

my $filetypes_supported_set =   grep { defined $lang{$_} && ($lang{$_} == 1) } @filetypes_supported;
my $filetypes_supported_unset = grep { defined $lang{$_} && ($lang{$_} == 0) } @filetypes_supported;

# If anyone says --noperl, we assume all other languages must be on.
if ( !$filetypes_supported_set ) {
    for ( keys %lang ) {
        $lang{$_} = 1 unless defined $lang{$_};
    }
}

if ( $opt{help} || (!@ARGV && !$opt{f}) ) {
    print <DATA>;  # Show usage
    exit 1;
}

my $re;

if ( !$opt{f} ) {
    $re = shift or die "No regex specified\n";

    if ( $opt{w} ) {
        $re = $opt{i} ? qr/\b$re\b/i : qr/\b$re\b/;
    }
    else {
        $re = $opt{i} ? qr/$re/i : qr/$re/;
    }
}


my $is_filter = !-t STDIN;
my @what;
if ( @ARGV ) {
    @what = @ARGV;

    # Show filenames unless we've specified one single file
    $opt{show_filename} = (@what > 1) || (!-f $what[0]);
}
else {
    if ( $is_filter ) {
        # We're going into filter mode
        for ( qw( f l ) ) {
            $opt{$_} and die "ack: Can't use -$_ when acting as a filter.\n";
        }
        $opt{show_filename} = 0;
        search( "-", $re, %opt );
        exit 0;
    }
    else {
        @what = ""; # Assume current directory
        $opt{show_filename} = 1;
    }
}
$opt{show_filename} = 0 if $opt{h};
$opt{show_filename} = 1 if $opt{H};

my $iter = interesting_files( \&is_interesting, !$opt{n}, @what );

while ( my $file = $iter->() ) {
    if ( $opt{f} ) {
        print "$file\n";
    }
    else {
        search( $file, $re, %opt );
    }
}
exit 0;

sub is_interesting {
    my $file = shift;

    return if $file =~ /~$/;
    return 1 if $opt{all};

    for my $type ( filetypes( $file ) ) {
        return 1 if $lang{$type};
    }
    return;
}

sub search {
    my $filename = shift;
    my $regex = shift;
    my %opt = @_;

    my $nmatches = 0;

    my $fh;
    if ( $filename eq "-" ) {
        $fh = *STDIN;
    }
    else {
        if ( !open( $fh, "<", $filename ) ) {
            warn "ack: $filename: $!\n";
            return;
        }
    }

    local $_;
    while (<$fh>) {
        if ( /$re/ ) {
            ++$nmatches;
            if ( $nmatches == 1 ) {
                # No point in searching more if we only want a list
                last if $opt{l};
            }
            next if $opt{v};

            my $out;

            if ( $opt{o} ) {
                $out = "$&\n";
            }
            else {
                $out = $_;
                $out =~ s/($re)/colored($1,"black on_yellow")/eg if $opt{color};
            }

            if ( $opt{show_filename} ) {
                my $colorname = $opt{color} ? colored( $filename, "bold green" ) : $filename;
                if ( $opt{group} ) {
                    print "$colorname\n" if $nmatches == 1;
                    print "$.:$out";
                }
                else {
                    print "${colorname}:$.:$out";
                }
            }
            else {
                print $out;
            }

            last if $opt{m} && ( $nmatches >= $opt{m} );
        } # match
        else { # no match
            if ( $opt{v} ) {
                print "${filename}:" if $opt{show_filename};
                print $_;
            }
        }
    } # while

    if ( $opt{l} ) {
        print "$filename\n" if ($opt{v} && !$nmatches) || ($nmatches && !$opt{v});
    }
    else {
        print "\n" if $nmatches && $opt{show_filename} && $opt{group} && !$opt{v};
    }

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
ack may also search STDIN, but only if no FILES are specified, or if
one of FILES is "-".

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
    -H                print the filename for each match
    -h                suppress the prefixing filename on output
    --[no]group       print a blank line between each file's matches
                      (default: on unless output is redirected)
    --[no]color       highlight the matching text (default: on unless
                      output is redirected, or on Windows)

File finding:
    -f                only print the files found, without searching.
                      The PATTERN must not be specified.

File inclusion/exclusion:
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
    --[no]sql         .sql and .ctl
    --[no]yaml        .yaml

Miscellaneous:
    --help            this help
    --version         display version
    --thpppt          Bill the Cat


GOTCHAS:
Note that FILES must still match valid selection rules.  For example,

    ack something --perl foo.rb

will search nothing, because foo.rb is a Ruby file.


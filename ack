#!/usr/local/bin/perl -w

=head1 NAME

ack - TW-specific grep-like program

=head1 DESCRIPTION

ack lets recursively grep through the TW source tree, using Perl
regular expressions.  It also color-codes results if appropriate.

=head1 TODO

Add a --[no]comment option to grep inside or exclude comments.

=cut

use strict;
use App::Ack;
use File::Find;
use Term::ANSIColor;

use Getopt::Long;

our @matched_filenames;
our $is_tty = -t STDOUT;

our $opt_h =        0;
our $opt_i =        0;
our $opt_l =        0;
our $opt_m =        0;
our $opt_n =        0;
our $opt_o =        0;
our $opt_v =        0;
our $opt_w =        0;
our $opt_group =    $is_tty;
our $opt_php =      1;
our $opt_perl =     1;
our $opt_shell =    1;
our $opt_sql =      1;
our $opt_test =     1;
our $opt_all =      0;
our $opt_color =    $is_tty;
our $opt_exec =     undef;
our $opt_help =     0;

GetOptions(
    l           => \$opt_l,
    "m=i"       => \$opt_m,
    n           => \$opt_n,
    o           => \$opt_o,
    i           => \$opt_i,
    v           => \$opt_v,
    w           => \$opt_w,
    h           => \$opt_h,
    "group!"    => \$opt_group,
    "test!"     => \$opt_test,
    "perl!"     => \$opt_perl,
    "php!"      => \$opt_php,
    "sql!"      => \$opt_sql,
    "shell!"    => \$opt_shell,
    "all!"      => \$opt_all,
    "color!"    => \$opt_color,
    "only"      => sub { $opt_php = $opt_perl = $opt_sql = $opt_test = 0 },
    "exec=s"    => \$opt_exec,
    "help"      => \$opt_help,
    "version"   => sub { print "ack $App::Ack::VERSION\n" and exit 1; },
) or $opt_help = 1;

if ( $opt_help || !@ARGV ) {
    print <DATA>;  # Show usage
    exit 1;
}

my $re = shift or die "No regex specified\n";

if ( $opt_w ) {
    $re = $opt_i ? qr/\b$re\b/i : qr/\b$re\b/;
} else {
    $re = $opt_i ? qr/$re/i : qr/$re/;
}

my @what = @ARGV ? @ARGV : ".";
find( \&handler, @what );

if ( $opt_exec ) {
    if ( @matched_filenames ) {
        warn "ack: Running $opt_exec with ", scalar @matched_filenames, " filenames\n";
        system( $opt_exec, @matched_filenames );
    } else {
        warn "No files matched, won't execute $opt_exec\n";
    }
}

sub handler {
    if ( -d ) {
        $File::Find::prune = 1 if m{ CVS }msx;
        $File::Find::prune = 1 if m{ .svn }msx;
        $File::Find::prune = 1 if $opt_n && ( $_ ne "." );
        return;
    }

    return if /~$/;

    return unless is_searchable( $_ );

    search( $_, $File::Find::name, $re );
}

sub is_searchable {
    my $filename = shift;

    return 1 if $opt_all;
    return ($opt_perl|$opt_test) if $filename =~ /\.t$/;
    return $opt_perl  if $filename =~ /\.(pl|pm|pod|tt|ttml|t)$/;
    return $opt_php   if $filename =~ /\.(phpt?|html?)$/;
    return $opt_shell if $filename =~ /\.k?sh$/;
    return $opt_sql   if $filename =~ /\.(sql|ctl)$/;
    return $opt_test  if $filename =~ /\.(php)?t$/;

    if ( $filename !~ /\./ ) {
        # No extension?  See if it's a shell script
        my $fh;
        if ( !open( $fh, "<", $filename ) ) {
            warn "Can't open $filename: $!\n";
            return;
        }
        my $header = <$fh>;
        close $fh;
        return unless defined $header;
        return $opt_perl  if $header =~ /^#.+perl\b/;
        return $opt_php   if $header =~ /^#.+php\b/;
        return $opt_shell if $header =~ /^#.+\/(ba|k)?sh\b/;
        return;
    }

    return;
}

sub search {
    my $filename = shift;
    my $dispname = shift;
    my $regex = shift;

    my $nmatches = 0;

    local $_;
    open( my $fh, $filename ) or die "Can't open $filename: $!";
    while (<$fh>) {
        if ( /$re/ ) {
            ++$nmatches;

            if ( $opt_exec ) {
                push( @matched_filenames, $dispname );
                last;
            }

            if ( $opt_l ) {
                print "$dispname\n";
                last;
            } # opt_exec

            # No point in still searching if we know we want negative match
            last if $opt_v;

            my $out;

            if ( $opt_o ) {
                $out = "$&\n";
            } else {
                $out = $_;
                $out =~ s/($re)/colored($1,"black on_yellow")/eg if $opt_color;
            }

            if ( $opt_h ) {
                print $out;
            } else {
                my $colorname = $opt_color ? colored( $dispname, "bold green" ) : $dispname;
                if ( $opt_group ) {
                    print "$colorname\n" if $nmatches == 1;
                    print "$.:$out";
                } else {
                    print "$colorname:$.:$out";
                }
            }

            last if $opt_m && ( $nmatches >= $opt_m );
        } # match
    } # while

    print "$dispname\n" if $opt_v && !$nmatches;
    print "\n" if $nmatches && ($opt_group && !$opt_l && !$opt_exec);

    close $fh;
}


__DATA__
Usage: ack [OPTION]... PATTERN [FILES]
Search for PATTERN in each file in the tree from cwd on down.
If [FILES] is specified, then only those files/directories
are checked.

Example: ack -i select

Output & searching:
    -i              ignore case distinctions
    -v              invert match: select non-matching lines
    -w              force PATTERN to match only whole words
    -l              only print filenames containing matches
    -o              show only the part of a line matching PATTERN
    -m=NUM          stop after NUM matches
    -h              don't print filenames
    --[no]group     print a blank line between each file's matches
                    (default: on unless output is redirected)
    --[no]color     highlight the matching text (default: on unless
                    output is redirected)
    --exec=command  no output, and run command with matching files as
                    arguments.  Equivalent to: command `ack -l ...`

File selection:
    -n              No descending into subdirectories
    --[no]php       .html, .php and .inc files        (default: on)
    --[no]perl      .pl, .pm, .pod, .t, .tt and .ttml (default: on)
    --[no]sql       .sql and .ctl files               (default: on)
    --[no]test      .t and .phpt files                (default: on)
    --[no]shell     shell scripts                     (default: on)
    --only          Only include files specificied by command switches
    --all           All files, regardless of extension

package App::Ack;

use warnings;
use strict;

=head1 NAME

App::Ack - A container for functions for the ack program

=head1 VERSION

Version 1.10

=cut

our $VERSION = '1.10';

use base 'Exporter';
our @EXPORT = qw( filetype );

=head1 SYNOPSIS

No user-serviceable parts inside.  F<ack> is all that should use this.

=head1 FUNCTIONS

=head2 filetype( $filename )

Tries to figure out the filetype of I<$filename>

=cut

sub filetype {
    my $filename = shift;

    return "cc"         if $filename =~ /\.[ch](pp)?$/;
    return "parrot"     if $filename =~ /\.(pir|pasm|pmc|ops)$/;
    return "perl"       if $filename =~ /\.(pl|pm|pod|tt|ttml|t)$/;
    return "php"        if $filename =~ /\.(phpt?|html?)$/;
    return "python"     if $filename =~ /\.py$/;
    return "ruby"       if $filename =~ /\.rb$/;
    return "shell"      if $filename =~ /\.(ba|c|k|z)?sh$/;
    return "sql"        if $filename =~ /\.(sql|ctl)$/;
    return "javascript" if $filename =~ /\.js$/;

    # No extension?  See if it has a shebang line
    if ( $filename !~ /\./ ) {
        my $fh;
        if ( !open( $fh, "<", $filename ) ) {
            warn "ack: $filename: $!\n";
            return;
        }
        my $header = <$fh>;
        close $fh;
        return unless defined $header;
        return "perl"   if $header =~ /^#.+\bperl\b/;
        return "php"    if $header =~ /^#.+\bphp\b/;
        return "python" if $header =~ /^#.+\bpython\b/;
        return "ruby"   if $header =~ /^#.+\bruby\b/;
        return "shell"  if $header =~ /^#.+\b(ba|c|k|z)?sh\b/;
        return;
    }

    return;
}

=head1 AUTHOR

Andy Lester, C<< <andy at petdance.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-ack at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ack>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

The App::Ack module isn't very interesting to users.  However, you may
find useful information about this distribution at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/ack>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/ack>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ack>

=item * Search CPAN

L<http://search.cpan.org/dist/ack>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2005-2006 Andy Lester, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

"It's just the normal noises in here."; # End of App::Ack

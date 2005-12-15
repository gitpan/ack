package App::Ack;

use warnings;
use strict;

=head1 NAME

App::Ack - A container for functions for the ack program

=head1 VERSION

Version 1.00

=cut

our $VERSION = '1.02';

use Exporter;
our @ISA    = 'Exporter';
our @EXPORT = qw( filetype );

=head1 SYNOPSIS

No user-serviceable parts inside.  F<ack> is all that should use this.

=head1 FUNCTIONS

=head2 filetype( $filename )

Tries to figure out the filetype of I<$filename>

=cut

sub filetype {
    my $filename = shift;

    return "cc"     if $filename =~ /\.[ch](pp)?$/;
    return "perl"   if $filename =~ /\.(pl|pm|pod|tt|ttml|t)$/;
    return "php"    if $filename =~ /\.(phpt?|html?)$/;
    return "shell"  if $filename =~ /\.[ckz]?sh$/;
    return "sql"    if $filename =~ /\.(sql|ctl)$/;

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
        return "perl"   if $header =~ /^#.+perl\b/;
        return "php"    if $header =~ /^#.+php\b/;
        return "shell"  if $header =~ /^#.+\/(ba|c|k|z)?sh\b/;
        return;
    }

    return;
}

=head1 AUTHOR

Andy Lester, C<< <andy at petdance.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-app-ack at rt.cpan.org>, or through the web interface at
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

Copyright 2005 Andy Lester, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

"It's just the normal noises in here."; # End of App::Ack

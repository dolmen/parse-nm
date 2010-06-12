use strict;
use warnings;

package Parse::nm;

our $VERSION = '0.05';

use Carp 'croak';
use Regexp::Assemble;
use String::ShellQuote;

sub new
{
    my ($class, %args) = @_;
    _build_filters(\%args);
    return bless \%args, (ref $class ? ref $class : $class);
}

sub _build_filters
{
    my ($args) = @_;

    unless (exists $args->{_comp_filters}) {
        $args->{_comp_filters} = [];
        $args->{_re} = Regexp::Assemble->new;
    }

    if (exists $args->{filters}) {
        my @f = @{$args->{filters}};
        for my $f (@f) {
            my $name = $f->{name} || '\S+';
            my $type = $f->{type} || '[A-Z]';
            $args->{_re}->add("^$name +$type +");
            push @{$args->{_comp_filters}}, [
                qr/^($name) +($type) +/, $f->{action}
            ];
        }
    }

    if (wantarray) {
        return @{$args->{_comp_filters}};
    } elsif (defined wantarray) {
        return exists $args->{_comp_filters};
    }
}


sub run
{
    my ($self, %args) = @_;
    %args = (%{$self}, %args) if ref $self;

    my @options = exists $args{options} ? @{$args{options}} : ();
    my @files = ref $args{files} ? @{$args{files}} : ($args{files});
    #open my $nm, 'nm '.join(' ', map { my $x = $_; $x =~ s/"/\\"/g; qq{"$x"} } @files).' |'
    open my $nm, '-|', shell_quote('nm', '-P', @options, @files)
        or croak "Can't run 'nm': $!";
    my $r = $self->parse($nm, %args);
    close $nm;
    return $r;
}


sub parse
{
    my ($self, $handle, %args) = @_;
    %args = (%{$self}, %args) if ref $self;
    _build_filters(\%args);
    my $re = $args{_re}->re;
    my $filters = $args{_comp_filters};
    while (<$handle>) {
        next unless /$re/;
        for my $f (@{$filters}) {
            if (/$f->[0]/) {
                $f->[1]($1, $2);
            }
        }
    }
    return ();
}

1;
__END__

=head1 NAME

Parse::nm - Run and parse 'nm' command output with filter callbacks

=head1 SYNOPSIS

Class interface:

    use Parse::nm;

    Parse::nm->run(options => [ qw(-e) ],
                   filters => [
                     {
                       name => qr/\.\w+/,
                       type => 'T',
                       action => sub {
                         print "$_[0]\n"
                       }
                     },
                   ],
                   files => 't.o',
                );

Object interface:

    use Parse::nm;

    my $pnm = Parse::nm->new(options => ...,
                             filters => ...);
    $pnm->run(files => 'file1.o');
    $pnm->run(files => 'file2.o');

    $str = "TestFunc T 0 0 \n";
    $pnm->parse(\$str);

=head1 METHODS

=head2 ->new(%options)

Builds an object with the default options.

=head2 ->parse(*GLOB, %options)

Parse 'nm -P'-style data coming from a filehandle.

Note that if your Perl is compiled with PerlIO (this is the default since
5.8.0), you can easily parse a string by opening a string reference to it.

    open($fh, '<', \$str)
a string 

=head2 ->run(%options)

Run C<nm> and parse its output.

=head1 OPTIONS

=over 4

=item options => [ ]

Command-line options given to C<nm> to run it.
The C<-P> (POSIX-style output) is always given.
C<-A> (show input file) is currently incompatible.

=item files => [ ]

List of files to give to C<nm> for parsing.

=item filters => \@filters

=over 4

=item name => qr/\S+/

A regexp that must match the name of the symbol.

Don't use C<^> or C<$>: this is not supported.

=item type => qr/[A-Z]/

A regexp that must match the type of the symbol. Types are single ASCII letter.
See the C<nm> man page of your operating system for more information.

Don't use C<^> or C<$>: this is not supported.

=item action => sub { ... }

A callback that will be triggered for each line where both C<name> and C<type>
match.

=back

=back

=head1 SEE ALSO

L<http://www.opengroup.org/onlinepubs/009695399/utilities/nm.html>

L<Binutils::Objdump>

=head1 AUTHOR

Olivier MenguE<eacute>, C<dolmen@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright E<copy> 2010 Olivier MenguE<eacute>.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself, either Perl version 5.12.0 or, at your option,
any later version of Perl 5 you may hava available.

=cut

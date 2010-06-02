use strict;
use warnings;

package Parse::nm;

our $VERSION = '0.03';

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

TODO

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
                   );

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

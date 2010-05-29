use strict;
use warnings;

package Parse::nm;

our $VERSION = '0.01';

use Regexp::Assemble;
use String::ShellQuote;

sub new
{
    my ($class, %args) = @_;
    _build_filters(\%args);
    bless \%args, (ref $class ? ref $class : $class);
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
            my $name = $f->{name};
            my $type = $f->{type};
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

    my @options = @{$args{options}};
    my @files = ref $args{files} ? @{$args{files}} : $args{files};
    #open my $nm, 'nm '.join(' ', map { my $x = $_; $x =~ s/"/\\"/g; qq{"$x"} } @files).' |'
    #    or die;
    open my $nm, shell_quote('nm', @options, @files).' |';
    return $self->parse($nm, %args);
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

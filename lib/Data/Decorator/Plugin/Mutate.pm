package Data::Decorator::Plugin::Mutate;

use Moo;
use namespace::autoclean;

with qw(
    Data::Decorator::Role::Plugin
);

sub _build_priority { 100 }

=method decorate

Receives a L<Data::Decorator::Result> object and performs the plugins transformations.

=cut

sub decorate {
    my ($self,$result) = @_;
}

1;

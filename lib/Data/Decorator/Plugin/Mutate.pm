package Data::Decorator::Plugin::Mutate;
# ABSTRACT: Deletes or renames entries

use Moo;
use namespace::autoclean;

with qw(
    Data::Decorator::Role::Plugin
);

# VERSION

sub _build_priority { 100 }

=method decorate

Receives a L<Data::Decorator::Result> object and performs the plugins transformations.

=cut

sub decorate {
    my ($self,$result) = @_;
}

1;

package Data::Decorator::Plugin::Mutate;
# ABSTRACT: Deletes or renames entries

use Moo;
use namespace::autoclean;

with qw(
    Data::Decorator::Role::Plugin
);

# VERSION

sub _build_priority { 100 }

=method lookup

Receives the source field name, destination field name, and the full document.

Returns a hash reference of updated keys/values.

=cut

sub lookup {
    my ($self,$src,$dst,$doc) = @_;
}

1;

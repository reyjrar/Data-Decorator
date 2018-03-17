package Data::Decorator::Plugin::Mutate;

use Moo;
use namespace::autoclean;

with qw(
    Data::Decorator::Role::Plugin
);

sub _build_priority { 100 }

sub decorate {
    my ($self,$result) = @_;
}

1;

use strict;
use Test::More;
use DDP;

use_ok('Data::Decorator');

my $empty = Data::Decorator->new(decorators => {});
my $empty_plugins = $empty->plugins;

ok(scalar keys %{ $empty_plugins }, "found plugins" );

done_testing;

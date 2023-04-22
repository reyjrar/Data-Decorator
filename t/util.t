use strict;
use warnings;

use Data::Decorator::Util qw(:all);
use Test::Deep;
use Test::More tests => 3;

subtest "hash_flatten_keys" => sub {
    cmp_deeply(
        [hash_flatten_keys({ foo => { bar => 1 } })],
        [qw(foo.bar)],
        "simple"
    );
    cmp_deeply(
        [hash_flatten_keys({ foo => { bar => [ { x => 1 }, { y => 1, z => 1 } ] } })],
        [qw(foo.bar.x foo.bar.y foo.bar.z)],
        "meddling arrays"
    );
};

subtest "hash_path_expand" => sub {
    cmp_deeply(
        hash_path_expand("foo.bar" => 1),
        { foo => { bar => 1 } },
        "simple"
    );
};

subtest "hash_path_get" => sub {
    cmp_deeply(
        hash_path_get("foo.bar" => { foo => { bar => 'baz' } }),
        "baz",
        "simple"
    );
};


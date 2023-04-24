use strict;
use warnings;

use Data::Decorator;
use Test::More tests => 3;

subtest 'mutate op: add' => sub {
    my $dd = Data::Decorator->new(
        decorators => {
            mutate => {
                plugin => 'Mutate',
                add => {
                    "bar" => "baz",
                },
            }
        }
    );
    ok($dd, "loaded object");

    my $doc = { foo => 1, src_ip => '8.8.8.8', dest => { ip => "1.2.3.4" } };
    my $res = $dd->decorate($doc);

    my $exp = { %$doc, "bar" => "baz" };
    is_deeply( $res->document, $exp,
        "add worked"
    );
};

subtest 'mutate op: remove' => sub {
    my $dd = Data::Decorator->new(
        decorators => {
            mutate => {
                plugin => 'Mutate',
                expand_hash_keys => 1,
                remove => [qw(a.b c)],
            }
        }
    );
    ok($dd, "loaded object");

    my $doc = { a => { b => 1 }, c => 1 };
    my $exp = { a => {}, };
    my $res = $dd->decorate($doc);
    is_deeply( $res->document, $exp,
        "remove simple"
    );
};

subtest 'mutate op: rename' => sub {
    my $dd = Data::Decorator->new(
        decorators => {
            mutate => {
                plugin => 'Mutate',
                expand_hash_keys => 1,
                rename => {
                    c => 'd',
                    a => 'e',
                }
            }
        }
    );
    ok($dd, "loaded object");

    my $doc = { a => { b => 1 }, c => 1 };
    my $exp = { e => { b => 1 }, d => 1 };
    my $res = $dd->decorate($doc);
    is_deeply( $res->document, $exp,
        "rename simple"
    );
};

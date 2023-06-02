use v5.16;
use warnings;
use FindBin qw($RealBin);
use Test::More tests => 2;
use Data::Decorator;


my $dd = Data::Decorator->new(
    decorators => {
        geoip => {
            plugin => 'GeoIP',
            geoip_file => "$RealBin/data/test.mmdb",
            fields => {
                src_ip => 'src_geo',
            }
        }
    },
);

my $geo = {
    city_name => 'Richmond',
};

my $doc = { src_ip => '10.0.1.1' };
my $exp = { %$doc, src_geoip => $geo };

my $res = $dd->decorate($doc);

is_deeply( $res->document, $exp,
    "geoip found and inserted data"
);

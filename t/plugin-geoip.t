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
            },
            no_cache => 1,
        }
    },
);

ok( @{ $dd->decorators }, "instantiated the geo decorator" );

# Geo Expected
my $geo = {
    city_name => 'Richmond',
    country => {
        iso_code => 'US',
    },
    location => "37,120",
};

# Document
my $doc = { src_ip => '192.168.0.1' };

# Assembled Document
my $exp = { %$doc, src_geo => $geo };

my $res = $dd->decorate($doc);
is_deeply( $res->document, $exp,
    "geoip found and inserted data"
);

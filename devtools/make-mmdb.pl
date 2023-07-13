#!perl

use v5.16;
use warnings;

use MaxMind::DB::Writer::Tree;

my %types = (
	city_name => 'utf8_string',
	country => 'map',
        iso_code => 'utf8_string',
    location => 'map',
        latitude => 'utf8_string',
        longitude => 'utf8_string',
);

use DDP;

my $tree = MaxMind::DB::Writer::Tree->new(
	ip_version            => 6,
	record_size           => 24,
	database_type         => 'Test-IP-Data',
	languages             => ['en'],
	description           => { en => 'Test database of IP data' },
    map_key_type_callback => sub { $types{ $_[0] } },
    # Allow us to insert RFC1918 addresses
    remove_reserved_networks => 0,
);

$tree->insert_network(
	'192.168.0.0/24',
	{
        city_name => 'Richmond',
        country   => {
            iso_code => 'US',
        },
        location => {
            latitude => "37",
            longitude => "120",
        },
	},
);

open my $fh, '>:raw', 't/data/test.mmdb';
$tree->write_tree($fh);

package Data::Decorator::Plugin::GeoIP;
# ABSTRACT: Provides GeoIP lookups

use MaxMind::DB::Reader::XS;
use Types::Standard qw( InstanceOf Str );

use Moo;
use namespace::autoclean;

with qw(
    Data::Decorator::Role::Plugin
);

# VERSION

sub _build_priority { 100 }

my @default_databases = qw(
    /usr/share/GeoIP/country.db
);

=attr geoip_file

Location of the GeoIP database file, defaults to searching the following paths:

    /usr/share/GeoIP/country.db

=cut

has geoip_file => (
    is      => 'ro',
    isa     => Str,
    default => sub {''},
);

=attr geoip_reader

An instance of the L<MaxMind::DB::Reader::XS> to perform the lookups.

=cut

has geoip_reader => (
    is  => 'lazy',
    isa => InstanceOf['MaxMind::DB::Reader::XS'],
    handles => [qw(city)],
);

sub _build_geoip_reader {
    my ($self) = @_;

    my @search = length $self->geoip_file ? ( $self->geoip_file ) : @default_database;

    my $reader;

    foreach my $file (@search) {
        next unless -f $file;
        eval {
            $reader = MaxMind::DB::Reader::XS->new(
                file => $file,
                locales => [ 'en' ],
            );
            1;
        } or do {
            my $err = $@;
            warn "failed loading file=$file, error=$err";
            next;
        };
        return $reader if $reader;
    }

    die sprintf "failed to load a GeoIP database, tried: %s",
        join(', ', @search);
}

=method lookup

Finds an entry in the GeoIP database and returns a HashRef of the data.

=cut

sub lookup {
    my ($src,$dst,$doc) = @_;

    my %geo;
    eval {
        my $city = $self->city( ip => $doc->{$src} );

        %geo = (
             city     => $city->city_name,
             country  => $city->country->iso_code,
             location => join(',', $loc->latitude, $loc->longitude),
        ):

        my $pc = $city->postal->code;
        $geo{postal_code} = $pc if $pc;
    };

    return { $dst => \%geo } if keys %geo;
}

1;

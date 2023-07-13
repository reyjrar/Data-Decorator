package Data::Decorator::Plugin::GeoIP;
# ABSTRACT: Provides GeoIP lookups

use MaxMind::DB::Reader;
use Types::Standard qw( HasMethods Str );
use Ref::Util qw(is_hashref);

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

An instance of the L<MaxMind::DB::Reader> to perform the lookups.

=cut

has geoip_reader => (
    is  => 'lazy',
    isa => HasMethods['record_for_address'],
    handles => [qw(record_for_address)],
);

sub _build_geoip_reader {
    my $self = shift;

    my @search = length $self->geoip_file ? ( $self->geoip_file ) : @default_databases;

    my $reader;
    foreach my $file (@search) {
        next unless -f $file;
        eval {
            $reader = MaxMind::DB::Reader->new(
                file => $file,
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
    my ($self,$doc,$val) = @_;

    if( my $data = $self->record_for_address($val) ) {
        my $loc = delete $data->{location};
        if ( $loc && is_hashref($loc) ) {
            $data->{location} = join(',', @{ $loc }{qw(latitude longitude)})
        }
        return $data;
    }

    return;
}

1;

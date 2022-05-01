package Data::Decorator::Plugin::DNS::Reverse;
# ABSTRACT: Get the reverse record for any IP records

use Moo;
use Net::DNS;
use Socket qw( inet_pton AF_INET AF_INET6 );
use Types::Standard qw( InstanceOf );
use namespace::autoclean;

with qw(
    Data::Decorator::Role::Plugin
);

=head1 Plugin Config

    * Cache Expiry is set to 1h
    * Priority set to 25

=cut

sub _build_cache_expiry { '1h' }
sub _build_priority     { 25 }

=attr nameserver

A L<Net::DNS::Resolver> object, if the plugin config section has a C<resolver>
section, those paramaters will be passed as is to L<Net::DNS::Resolver>.

=cut

has 'nameserver' => (
    is => 'lazy',
    isa => InstanceOf['Net::DNS::Resolver'],
);

sub _build_nameserver {
    my ($self) = @_;
    my %opts = %{ $self->config->{resolver} };
    return Net::DNS::Resolver->new(%opts);
}

=method decorate

Takes an L<Data::Decorator::Result> object and scans for source fields with IP
addresses and performs a reverse DNS lookup.

=cut

sub decorate {
    my ($self,$result) = @_;

    my $fields = $self->fields;
    my $doc    = $result->document;
    foreach my $src ( sort keys %{ $fields } ) {
        next unless length $doc->{$src};
        my $dst = $fields->{$src};

        my $reverse = $self->cache->compute( $doc->{$src} => sub {
            my $result = $self->nameserver->query( $doc->{$src}, 'PTR' );
            use DDP;
            p($result);
        });

        if( length $reverse ) {
            $result->add( $src, { $dst => $reverse } );
        }
    }
}

1;

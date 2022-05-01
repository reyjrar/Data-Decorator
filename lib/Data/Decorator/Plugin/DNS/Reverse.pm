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

=head1 Plugin Overrides

    * Cache Expiry is set to 5m
    * Priority set to 25

=head1 Plugin Config Options

These are the options to specify in the C<config> block when instantiating an object.

=over 2

=item B<resolver>

A hash reference of options to pass to L<Net::DNS::Resolver> which will be used for the lookups.

=item B<no_cache>

Set to true to completely disable the file system caching.

=back

=head1 Example Config

    use Data::Decorator;

    my $dd = Data::Decorator->new(
        decorators => {
            rdns => {
                plugin => 'DNS::Reverse',
                fields => {
                    dst_ip => 'dst_rdns',
                    src_ip => 'src_rdns',
                },
                config => {
                    resolver => {
                        nameservers => [ qw(localhost) ],
                        port => 8053,
                    }
                }
            }
        }
    );

    my $doc = { src_ip => '127.0.0.1' };

    my $result = $dd->decorate($doc);

    print encode_json($result->document);
    # { 'src_ip': '127.0.0.1', src_rdns => 'localhost.localdomain.' };

=cut

sub _build_cache_expiry { '5m' }
sub _build_priority     { 25 }

=attr nameserver

A L<Net::DNS::Resolver> object, if the plugin config section has a C<resolver>
section, those paramaters will be passed as is to L<Net::DNS::Resolver>.

=cut

has 'nameserver' => (
    is  => 'lazy',
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

        my $lookup = sub {
            my $resp = $self->nameserver->query( $doc->{$src}, 'PTR' );
            # Use the first answer (should be first and only)
            my ($answer) = $resp->answer;
            return $answer->rdstring;
        };

        my $reverse = $self->config->{no_cache} ? $lookup->()
                    : $self->cache->compute( $doc->{$src} => $lookup );

        if( defined $reverse ) {
            $result->add( $src, { $dst => $reverse } );
        }
    }
}

1;

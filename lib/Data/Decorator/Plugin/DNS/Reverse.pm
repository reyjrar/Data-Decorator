package Data::Decorator::Plugin::DNS::Reverse;
# ABSTRACT: Get the reverse record for any IP records

use Moo;
use Net::DNS;
use Socket qw( inet_pton AF_INET AF_INET6 );
use Types::Standard qw( Bool InstanceOf );
use namespace::autoclean;

with qw(
    Data::Decorator::Role::Plugin
);

# VERSION

=head1 Plugin Overrides

    * Cache Expiry is set to 5m
    * Priority set to 25

=head1 Plugin Config Options

These are the options to specify in the C<config> block when instantiating an object.

=over 2

=item B<resolver>

A hash reference of options to pass to L<Net::DNS::Resolver> which will be used for the lookups.

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

=attr report_errors

If set to true (the default), then the rcode will be returned for fields where
there was an error.

=cut

has report_errors => (
    is      => 'ro',
    isa     => Bool,
    default => sub {1},
);

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

=method lookup

Takes an L<Data::Decorator::Result> object and scans for source fields with IP
addresses and performs a reverse DNS lookup.

=cut

sub lookup {
    my ($self,$doc,$val) = @_;

    if( my $resp = $self->nameserver->query( $val, 'PTR' ) ) {
        if( $resp->header->rcode eq 'NOERROR' ) {
            # Use the first answer (should be first and only)
            my ($answer) = $resp->answer;
            return $answer->rdstring;
        }
        elsif( $self->report_errors ) {
            return { error => $resp->header->rcode };
        }
    }
    elsif( $self->report_errors ) {
        return { error => "lookup failed" };
    }

    return $self;
}

1;

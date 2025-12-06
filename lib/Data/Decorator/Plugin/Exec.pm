package Data::Decorator::Plugin::Exec;
# ABSTRACT: Execute a command and use the output to augment the record

use Moo;
use Types::Standard qw( Bool InstanceOf );
use namespace::autoclean;

with qw(
    Data::Decorator::Role::Exec
    Data::Decorator::Role::Plugin
    Data::Decorator::Role::Template
);

# VERSION

=head1 Plugin Overrides

    * Cache Expiry is set to 5m
    * Priority set to 25

=head1 Plugin Config Options

These are the options to specify in the C<config> block when instantiating an object.

=head1 Example Config

    use Data::Decorator;

    my $dd = Data::Decorator->new(
        decorators => {
            username => {
                plugin => 'Exec',
                fields => {
                    user_id => 'username',
                },
                config => {
                    command => 'find-username',
                    args    => ['by-id', '{{ doc.user_id }}'],
                }
            }
        }
    );

    my $doc = { user_id => 99 };

    my $result = $dd->decorate($doc);

    print encode_json($result->document);
    # { 'user_id': 99, username => 'nobody' };

=cut

sub _build_cache_expiry { '5m' }
sub _build_priority     { 25 }

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

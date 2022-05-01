package Data::Decorator::Plugin::SQL;

use DBIx::Connector;

use Moo;
use namespace::autoclean;

with qw(
    Data::Decorator::Role::Exec
    Data::Decorator::Role::Plugin
);

=attr connector

This is the L<DBIx::Connector> object to use.

=cut

has 'connector' => (
    is => 'lazy',
);

sub _build_connector {
    my ($self) = @_;

    my $config = $self->config;
    my @required = qw( dsn username );

    if( my $conn = $config->{connection} ) {
        my @missing = ();
        foreach my $k ( @required ) {
            next if $conn->{$k};
            push @missing, $k;
        }
        if( !$conn->{password} and !$conn->{password_exec} ) {
            push @missing, "password or password_exec";
        }
        # Ensure we have all the parameters
        die sprintf ("%s - missing parameters in config block: %s",
            __PACKAGE__, join(', ', @missing);
        ) if @missing;

        my $password = $conn->{password} // $self->exec_command( $conn->{password_exec} );
        # TODO: Instantiate handle
        return DBIx::Connector->new(@{ $conn }{qw(dsn username)}, $password);
    }
    else {
        die sprintf "%s - missing config section with dsn, username, and password or password_exec",
            __PACKAGE__;
    }
}

=method decorate()

Implements the plugin specific decoration operations

=cut

sub decorate {
    my ($self,$result) = @_;

    my $c = $self->config;
}

1;

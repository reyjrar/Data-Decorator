package Data::Decorator::Plugin::SQL;
# ABSTRACT: Adds elements to a document from a SQL database

use DBIx::Connector;

use Moo;
use Types::Standard qw( ArrayRef Str );
use namespace::autoclean;

with qw(
    Data::Decorator::Role::Exec
    Data::Decorator::Role::Plugin
);

# VERSION

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

=attr query

A SQL statement to execute.  Use C<?> to setup parameters.  Using the C<params>
parameter to drop data into the query. e.g.,

    my $d = Data::Decorator::Plugin::SQL->new(
        config => {
            dsn => ...,
            username => ...,
            password => ...,
        },
        query => q{
            SELECT
                field
            FROM table
            WHERE id = ?
        },
        params => [ "id" ],
        fields => {
            id => 'sql',
        },
    );

The above would use the C<id> field in every document to retrieve the result
and stash the value in the C<sql> field.

=cut

has query => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

=attr params

An array reference listing the field names in the document to use at each
placeholder.

=cut

has params => (
    is      => 'ro',
    isa     => ArrayRef,
    default => sub {[]},
);

has _sth => (
    is => 'lazy',
    init_arg => undef.
)

sub _build_sth {
    my ($self) = @_;

    return $self->connector->run( fixup => sub {
        my ($dbh) = @_;
        return $dbh->prepare( $self->query );
    });
}

=method lookup()

Implements the plugin specific decoration operations

=cut

sub lookup {
    my ($self,$src,$dst,$doc) = @_;

    my @expected = @{ $self->params };
    my @params = map { $doc->{$_} // () } @expected;

    if( @expected == @params ) {
        $self->_sth->execute(@params);
        if( $self->_sth->rows() ) {
            my @values = ();
            while ( my $row = $self->_sth->fetchrow_hashref ) {
                if( keys %{ $row } == 1 ) {
                    push @values, values %{ $row };
                }
                else {
                    push @values, $row;
                }
            }
            if( @values ) {
                return { $dst => @values == 1 ? $values[0] : \@values };
            }
        }
    }
}

1;

package Data::Decorator::Util;

use v5.16;
use warnings;

# VERSION

use Sub::Exporter -setup => {
    exports => [ qw(
        hash_flatten_keys hash_path_del hash_path_get hash_path_expand
    )],
    groups => {
        hash    => [qw(hash_flatten_keys hash_path_del hash_path_get hash_path_expand)],
        default => [qw(hash_flatten_keys hash_path_del hash_path_get hash_path_expand)],
    },
};

use Ref::Util qw(is_arrayref is_hashref is_ref);

=func hash_flatten_keys(hashref)

Returns a list of flattened hash keys from the hash

=cut

sub hash_flatten_keys {
    my ($ref,@path) = @_;

    return join(".", @path) unless is_ref($ref);
    my @collected = ();
    if( is_arrayref($ref) ) {
        foreach my $elm ( @{ $ref } ) {
            push @collected, hash_flatten_keys($elm,@path);
        }
    }
    elsif( is_hashref($ref) ) {
        foreach my $k (sort keys %{ $ref }) {
            push @collected, hash_flatten_keys($ref->{$k}, @path, $k);
        }
    }

    return @collected;
}


=func hash_path_del(path, hashref)

Deletes and returns the data at the requested location, supports "x.c" style keys as hash paths.

=cut

sub hash_path_del {
    my ( $path, $doc ) = @_;

    # Simplest case
    return delete $doc->{$path} if $doc->{$path};

    my @path = split /\.+/, $path;
    my $key  = pop @path;

    my $ref = $doc;
    foreach my $part ( @path ) {
        return unless $ref->{$part};
        $ref = $ref->{$part};
    }

    return delete $ref->{$key};
}

=func hash_path_get(path, hashref)

Returns the data at the requested location, supports "x.c" style keys as hash paths.

=cut

sub hash_path_get {
    my ( $path, $doc ) = @_;

    # Simplest case
    return $doc->{$path} if $doc->{$path};

    my @path = split /\.+/, $path;
    my $key  = pop @path;

    my $ref = $doc;
    foreach my $part ( @path ) {
        return unless $ref->{$part};
        $ref = $ref->{$part};
    }

    return $ref->{$key};
}

=func hash_path_expand( path, value )

Takes two arguments, a path and a value.

Given:

    "foo.bar.baz" => 1

Returns:

    { foo => { bar => { baz => 1 } } }

=cut

sub hash_path_expand {
    my ($path, $value) = @_;

    my @path = split /\.+/, $path;
    my $key  = pop @path;

    # Build the document
    my $doc = {};
    my $ref = \$doc;
    foreach my $part ( @path ) {
        # Create a new anonymous hash
        my $hash = {};
        # Dereference and install the hash at the new path
        ${ $ref }->{$part} = $hash;
        # Move our reference to that new hash
        $ref = \$hash;
    }

    # Add the key
    ${ $ref }->{$key} = $value;
    return $doc;
}

1;

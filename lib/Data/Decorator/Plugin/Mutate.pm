package Data::Decorator::Plugin::Mutate;
# ABSTRACT: Deletes or renames entries

use Data::Decorator::Util qw(:hash);
use Types::Standard qw(ArrayRef Bool HashRef);

use Moo;
use namespace::autoclean;

with qw(
    Data::Decorator::Role::Plugin
);

# VERSION

sub _build_level    { 'documents' }
sub _build_no_cache { 1 }
sub _build_priority { 100 }

=attr add

A HashRef of K/V pairs to add to the document

=cut

has add => (
    is      => 'ro',
    isa     => HashRef,
    default => sub { {} }
);

=attr allow_override

For `add` and `rename` actions, should we allow overriding the destination
fields if they exists, B<defaults to 1>.

=cut

has allow_override => (
    is      => 'ro',
    isa     => Bool,
    default => sub { 1 }
);


=attr remove

An ArrayRef of keys to remove from the document

=cut

has remove => (
    is      => 'ro',
    isa     => ArrayRef,
    default => sub { [] }
);

=attr rename

A HashRef of C<src>/C<dst> key pairs to rename C<src> to C<dst>.

=cut

has rename => (
    is      => 'ro',
    isa     => HashRef,
    default => sub { {} }
);

=method lookup

Receives the document and performs to requested mutations directly to the document.

=cut

sub lookup {
    my ($self,$doc) = @_;

    # Add fields
    my $add = $self->add;
    foreach my $k ( sort keys %{ $add } ) {
        next if $doc->{$k} && !$self->allow_override;
        $doc->{$k} = $add->{$k};
    }

    # Rename fields
    my $rename = $self->rename;
    foreach my $k ( sort keys %{ $rename } ) {
        next if $doc->{$rename->{$k}} && !$self->allow_override;
        $doc->{$rename->{$k}} = hash_path_del($k,$doc)
    }

    # Simplest, just remove the field
    foreach my $k ( @{ $self->remove } ) {
        hash_path_del( $k, $doc );
    }

    return $doc;
}

1;

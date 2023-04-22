package Data::Decorator::Result;
# ABSTRACT: Result Object for a Data Decoration Operation

use Data::Decorator::Util qw(:hash);
use Hash::Merge::Simple qw( dclone_merge );
use Ref::Util qw(is_arrayref is_hashref is_ref);
use Storable qw(dclone);
use Types::Standard qw( Str ArrayRef HashRef );

use Moo;
use namespace::autoclean;

# VERSION

# Private: Original Document
has _orig => (
    is       => 'ro',
    isa      => HashRef,
    required => 1,
    init_arg => 'document',
);

=attr document

The resulting document after all decorators have run.

=cut

has document => (
    is       => 'rw',
    isa      => HashRef,
    init_arg => undef,
    builder  => sub {
        dclone( $_[0]->_orig )
    },
);

has _fields => (
    is      => 'rw',
    isa     => HashRef,
    default => sub { {} },
);

=method added_fields( @list_of_src_keys )

Takes an optional list of src fields, if present only fields added by
inspecting those fields will be returned.

The default option returns a list of all the new fields in the document.

=cut

sub added_fields {
    my ($self,@keys) = @_;

    @keys = sort keys %{ $self->_orig }
        unless @keys;

	my $fields = $self->_fields;
    my @fields = ();
    foreach my $k ( @keys ) {
        push @fields, exists $fields->{$k} ?
                      (is_arrayref( $fields->{$k} ) ? @{ $fields->{$k} } : $fields->{$k})
                      : ();
    }
    return \@fields;
}

=method add( src_field => hash_ref )

Takes a source field name and the hash of keys/values to add to the result.

Returns itself, for chaining add calls.

=cut

sub add {
    my ($self, $src_field, $data) = @_;

    my $doc    = $self->document;
    my $fields = $self->_fields;

    $self->document(dclone_merge($doc,$data));

    $fields->{$src_field} ||= [];
    my %existing = map { $_ => 1 } @{ $fields->{$src_field} };

    push @{ $fields->{$src_field} },
        grep { !$existing{$_} } hash_flatten_keys($data);

    return $self;
}

1;

package Data::Decorator::Result;
# ABSTRACT: Result Object for a Data Decoration Operation

use Ref::Util qw(is_arrayref is_hashref);
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
    is       => 'lazy',
    isa      => HashRef,
    init_arg => undef,
);

# Clone the Original Document
sub _build_document { dclone( $_[0]->_orig ) }

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

=cut

sub add {
    my ($self, $src_field, $data) = @_;

    my $doc    = $self->document;
    my $fields = $self->_fields;

    foreach my $k ( sort keys %{ $data } ) {
        # Make sure there's data
        next unless length $data->{$k};
        # Record adding a field
        push @{ $fields->{$src_field} }, $k
            unless grep { $k eq $_ } @{ $fields->{$src_field} };
        # Add the data
        if( exists $doc->{$k} ) {
            if( is_arrayred($doc->{$k}) ) {
                push @{ $doc->{$k} }, $data->{$k};
            }
            else {
                $doc->{$k} = [ $doc->{$k}, $data->{$k} ];
            }
        }
        else {
            $doc->{$k} = $data->{$k};
        }
    }
}

1;

package Data::Decorator::Role::Plugin;
# ABSTRACT: Common interface for implementing an Data::Decorator plugin

use Moo::Role;
use Types::Standard qw(Bool HashRef Int Str);

with qw(
    Data::Decorator::Role::Cache
);

# VERSION

=head1 SYNOPSIS

Provides the interface to load L<Data::Decorator> plugins in the correct order.


    package MyApp::Decorators::Db::LookUpEmployee;

    use Moo::Role;
    with qw( Data::Decorator::Plugin );


=head1 INTERFACE

=head2 lookup

This method will be called everytime a document matches this context.  It receives
a copy of the HashRef it was passed, return the decorated HashRef.

=cut

requires qw(
    lookup
);

around lookup => sub {
    my $orig = shift;
    my $self = shift;

    if( $self->no_cache ) {
        return $orig->($self,@_);
    }

    my ($src,$dst,$doc) = @_;

    return $self->cache->compute($doc->{$src}, sub {
        $self->lookup(@_);
    });
};

=attr name

The name of the plugin.  Defaults to stripping the plugin namespace from the
object's class name and replacing '::' withn an underscore.

=cut

has name => (
    is  => 'lazy',
    isa => Str,
);

sub _build_name {
    my ($self) = @_;
    my ($class) = ref $self;
    my ($namespace) = $self->namespace;
    # Trim Name Space
    my $name = $class =~ s/^${namespace}:://r;

    # Replace colons with underscores
    return $name =~ s/::/_/gr;
}

=attr priority

An integer representing the priority ordering of the plugin in loading, lower
priority will appear in the beginning of the plugins list. Defaults to 50.

=cut

has 'priority' => (
    is  => 'lazy',
    isa => Int,
);
sub _build_priority  { 50 }

=attr enabled

Boolean indicating if the plugin is enabled by default.  Defaults
to true.

=cut

has 'enabled' => (
    is => 'lazy',
    isa => Bool,
);
sub _build_enabled   { 1 }

=attr namespace

The primary namespace for these plugins.  This is used to auto_trim it from the
plugin's name for simpler config templates.

This is a B<required> parameter.

=cut

has 'namespace' => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

=attr fields

Field mapping for the data decoration as a hashref, ie:

    fields:
      src_ip: src_rdns

Tells the decorator plugin to use C<src_ip> as the source field for its
lookup, and to store the results in the C<src_rdns> field.

Decorators which return more than one key/value will use this key as the root
key for the data element.  Consider we use the C<GeoIP> decorator, which
returns a hash, and we used this config:

    fields:
      src_ip: src_geoip

Documents that match this rule, will end up adding the hash returned at the
C<src_geoip> space, or

    src_ip: 1.2.3.4
    src_geoip:
      city: Baltimore
      cc: US
      location: ...
=cut

has fields => (
    is      => 'ro',
    isa     => HashRef,
    default => sub {{}},
);

=attr config

Config parameter for the plugin as a hash reference.

=cut

has config => (
    is      => 'ro',
    isa     => HashRef,
    default => sub {{}},
);

=attr is_final

If this is set to true, any documents matching this plugin will skip evaluation
of any remaining plugins.  The default is false.  Use sparringly, it exists,
but you probably won't need it.

=cut

has 'is_final' => (
    is       => 'ro',
    isa      => Bool,
    default  => sub { 0 },
);

=head1 SEE ALSO

L<Data::Decorator>, L<Data::Decorator::Role::PluginLoader>

=cut

1;

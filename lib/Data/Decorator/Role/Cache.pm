package Data::Decorator::Role::Cache;
# ABSTRACT: Common interface for caching results in plugins

use CHI;
use Moo::Role;
use Types::Standard qw(Bool HashRef InstanceOf Int Str);

# VERSION

=head1 SYNOPSIS

Provides the interface to cache data in plugins.


    package MyApp::Decorators::Db::LookUpEmployee;

    use Moo::Role;
    with qw( Data::Decorator::Cache );


=attr cache_namespace

The cache namespace to use, defaults to the instance name.

=cut

has cache_namespace => (
    is  => 'lazy',
    isa => Str,
);

sub _build_cache_namespace { $_[0]->name }

=attr cache_expiry

Default cache expiry, defaults to C<1d>.

=cut

has cache_expiry => (
    is  => 'lazy',
    isa => Str,
);

sub _build_cache_expiry { '1d' }

=attr cache_root_dir

Default cache root dir, defaults to C<$HOME/.cache/data-decorator>.

Can be overridden in config via the C<root_dir> parameter to the config section.

=cut

has cache_root_dir => (
    is  => 'lazy',
    isa => Str,
);

sub _build_cache_root_dir { "$ENV{HOME}/.cache/data-decorator" }

=attr cache_config

Passed in as C<cache> init attribute.  Pass in your custom L<CHI> config,
defaults to using the C<File> driver.

=cut

has cache_config => (
    is       => 'ro',
    isa      => HashRef,
    init_arg => 'cache',
);

=attr cache

This is the assembled C<CHI> instance.

=cut

has cache => (
    is  => 'lazy',
    isa => InstanceOf['CHI'],
);

sub _build_cache {
    my ($self) = @_;

    my %default = (
        expires_in => $self->cache_expiry,
        namespace  => $self->cache_namespace,
    );
    my %params = ();
    my $params = $self->cache_config();

    # NOTE: If the user defines a driver, we trust their config, otherwise we
    #       assume the default and assemble a reasonable config.
    if( $params->{driver} ) {
        %params = %{ $params };
    }
    else {
        %params = (
            driver   => 'File',
            root_dir => $params->{root_dir} || $self->cache_root_dir,
        );
    }

    # I do love Perl's list context
    return CHI->new( %default, %params );
}

1;
__END__

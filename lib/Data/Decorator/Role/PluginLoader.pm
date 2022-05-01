package Data::Decorator::Role::PluginLoader;

# ABSTRACT: Implements the plumbing for an object to support plugins

use List::Util qw(any);
use Module::Pluggable::Object;
use Module::Load qw(load);
use Ref::Util qw(is_arrayref);
use Types::Standard qw(ArrayRef HashRef InstanceOf Str);

use Moo::Role;
use namespace::autoclean;

# VERSION

=head1 SYNOPSIS

Implements helpers around creating plugins to make things easier to
plug.

    package Data::Decorator;

    use Moo;
    with qw(Data::Decorator::Role::Pluggable);

    sub _build_namespace { 'Data::Decorator::Plugin' }

    sub find {
        my ($self,$log) = @_;

        foreach my $p ($self->plugins) {}
    }

    package main;

    my $decorator = Data::Decorator->new(
        search_path => [ qw( MyApp::Decorator ) ],
        disabled    => [ qw( Data::Decorator::Plugin::GeoIP ) ],
    );

=attr namespace

Primary namespace for the plugins for this object. No default provided, you
must implement C<_build_namespace> in your plugin.

=cut

has namespace => (
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    builder => '_build_namespace',
);

=attr search_path

An ArrayRef of additional namespaces or directories to search to load our
plugins.  Default is an empty array.

=cut

has search_path => (
    is      => 'ro',
    isa     => ArrayRef[Str],
    lazy    => 1,
    default => sub { [] },
);

=attr disabled

An ArrayRef of explicitly disallowed package namespaces to prevent loading.
Default is an empty array.

=cut

has disabled => (
    is      => 'ro',
    isa     => ArrayRef[Str],
    lazy    => 1,
    default => sub { [] },
);

=attr loader

An instance of L<Module::Pluggable::Object> to use to locate plugins.

You shouldn't need this considering the options available, but always nice
to have the option to override it with C<_build_loader>.

B<This plugin class expects the loader's plugin() call to return a list of
class names, not instantiated objects.>

=cut

has 'loader' => (
    is      => 'ro',
    isa     => InstanceOf['Module::Pluggable::Object'],
    lazy    => 1,
    builder => '_build_loader',
);

sub _build_loader {
    my ($self) = @_;
    my $loader = Module::Pluggable::Object->new(
        search_path => [ $self->namespace, @{$self->search_path} ],
        except      => $self->disabled,
    );
    return $loader;
}

has 'plugins' => (
    is  => 'lazy',
    isa => HashRef,
);

sub _build_plugins {
    my ($self) = @_;

    my %plugins = ();
    foreach my $plugin ( $self->loader->plugins ) {
        eval {
            load $plugin;
            1;
        } or do {
            my $err = $@;
            warn "Found $plugin, but could not load it: $err";
            next;
        };
        # Install Aliases
        foreach my $path ( $self->namespace, @{ $self->search_path } )  {
            if(index($plugin, $path) == 0) {
                # Grab Alias
                my $alias = substr($plugin, length($path) + 2 );
                if( exists $plugins{$alias} ) {
                    my $aliases = is_arrayref($plugins{$alias}) ? $plugins{$alias} : [];
                    push @{ $aliases }, $plugin;
                    $plugins{$alias} = $aliases;
                }
                else {
                    $plugins{$alias} = $plugin;
                }
            }
        }
        # Register the Class
        $plugins{$plugin} = $plugin;
    }
    foreach my $name (sort keys %plugins) {
        if( is_arrayref($plugins{$name}) ) {
            warn sprintf "Disabling alias '%s' as multiple plugins requested it: plugins=%s",
                $name, join( ',', sort @{ $plugins{$name} } );
            delete $plugins{$name};
        }
    }
    return \%plugins;
}

=head1 SEE ALSO

L<Module::Object::Pluggable>

=cut

1;

package Data::Decorator::Role::PluginLoader;

# ABSTRACT: Implements the plumbing for an object to support plugins

use List::Util qw(any);
use Moo::Role;
use Types::Standard qw(ArrayRef HashRef InstanceOf Str);
use namespace::autoclean;
use Module::Pluggable::Object;

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

        foreach my $p ($self->plugins) {
            return $p->name if $p->match_log($log);
        }
    }

    package main;

    my $decorator = Data::Decorator->new(
        search_path => [ qw( MyApp::Decorator ) ],
        disabled    => [ qw( Data::Decorator::Plugin::GeoIP ) ],
        config      => {
            Referer => { DomainList => '/var/db/bad_domains' },
        }
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
        require     => 1,
    );
    return $loader;
}

=attr plugins_config

A HashRef of configs for passing along to our plugins. The init arg for this
parameter is 'config' to simplify instantiation and config files.

Special considerations are taken when processing the hash.  The C<namespace> and C<search_path> are
automatically prepended to all keys to allow pretty config.  This means I can pass a config like this:

    my $decorator = Data::Decorator->new(
        search_path => [qw(MyApp::Decorators)],
        config => {
            GeoIP               => { enabled => 1 },
            DNS::Reverse        => { enabled => 0 },
            Data::Decorator::Plugin::GeoIP => { enabled => 0 },
        },
    );

This will expand the config to:

        config => {
            MyApp::Decoratos::GeoIP               => { enabled => 1 },
            MyApp::Decorators::DNS::Reverse       => { enabled => 0 },
            Data::Decorator::Plugin::DNS::Reverse => { enabled => 0 },
            Data::Decorator::Plugin::GeoIP        => { enabled => 0 },
        },

The explicit config for 'Data::Decorator::Plugin::GeoIP' is retained.

=cut

has 'plugins_config' => (
    is       => 'ro',
    isa      => HashRef,
    default  => sub {{}},
    init_arg => 'config',
);

=attr plugins

The priority sorted list of plugin objects found by the loader.  The C<plugins> call
expects the C<loader> function to return a list of class names, not objects.

=cut

has 'plugins' => (
    is => 'ro',
    isa => ArrayRef,
    lazy => 1,
    builder => '_build_plugins',
);

sub _build_plugins {
    my $self = shift;
    my @plugins = ();

    # Make short hand configs possible
    my %config = ();
    my @search = grep { defined && length } ($self->namespace, @{ $self->search_path });
    foreach my $alias ( keys %{ $self->plugins_config } ) {
        # Copy into our local hash
        $config{$alias} = $self->plugins_config->{$alias};
        # If we find our search path as a prefix, skip
        next if any { /^$alias/ } @search;
        foreach my $prefix (@search) {
            my $class = join('::', $prefix, $alias);
            next if exists $config{$class};
            # Copy the config
            $config{$class} = $config{$alias};
        }
    }
    foreach my $class ( $self->loader->plugins ) {
        eval {
            my $opts = $config{$class} || {};
            $opts->{namespace} = $self->namespace;
            push @plugins, $class->new(%{ $opts });
            1;
        } or do {
            my $err = $@;
            ## no critic
            no strict 'refs';
            my $warn_var = sprintf '%s::SuppressWarnings', $class;
            my $suppress_warnings = eval "$$warn_var" || 0;
            warn $err unless $suppress_warnings;
            ## use critic
        };
    }
    return [
        sort { $a->priority <=> $b->priority || $a->name cmp $b->name }
        grep { $_->enabled }
        @plugins
    ];
}

=head1 SEE ALSO

L<Module::Object::Pluggable>

=cut

1;

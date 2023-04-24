package Data::Decorator;
# ABSTRACT: Data Decorator Adds Context to Hashes

use List::Util      qw( any );
use Ref::Util       qw( is_ref is_arrayref is_coderef is_regexpref );
use Time::HiRes     qw( gettimeofday tv_interval );
use Types::Standard qw( ArrayRef ConsumerOf HashRef );
use Storable        qw( dclone );

use Data::Decorator::Result;
use Data::Decorator::Util qw(:hash);

use Moo;
use namespace::autoclean;

# VERSION

with qw(
    Data::Decorator::Role::PluginLoader
);

sub _build_namespace { 'Data::Decorator::Plugin' }

=attr decorators_config

B<Init Arg is decorators>.

Config for the decorators to load.

=cut

has decorators_config => (
    is       => 'ro',
    isa      => HashRef,
    init_arg => 'decorators',
    default  => sub {{}},
);


=attr decorators

A hash ref of named decorator objects with their initialization parameters,

=cut

has 'decorators' => (
    is       => 'lazy',
    isa      => ArrayRef[ConsumerOf['Data::Decorator::Role::Plugin']],
    init_arg => undef,
);

sub _build_decorators {
    my($self) = @_;

    my $config     = $self->decorators_config;
    my $plugins    = $self->plugins;
    my @decorators = ();

    foreach my $name ( sort keys %{ $config } ) {
        my $def = $config->{$name};
        do {
            warn "missing plugin attribute: name=$name";
            next;
        } unless $def->{plugin};

        my $class = delete $def->{plugin};

        do {
            warn sprintf "unknown plugin requested: name=%s requested=%s available=%s",
                $name, $class, join(',', sort keys %{ $plugins });
            next;
        } unless exists $plugins->{$class};

        eval {
            my $instance = $plugins->{$class}->new(
                namespace => $self->namespace,
                name => $name,
                %{ $def }
            );
            push @decorators, $instance if $instance->enabled;
            1;
        } or do {
            my $err = $@;
            warn "failed to create an instance of plugin: name=$name plugin=$class err=$err";
        };
    }

    return [ sort { $a->priority <=> $b->priority || $a->name cmp $b->name } @decorators ];
}


=method decorate

Takes a HashRef and iterates through all the available plugins applying a
their transformations to the HashRef by calling their C<decorate> method.

=cut

sub decorate {
    my ($self,$orig) = @_;

    my $result = Data::Decorator::Result->new( document => $orig );
    my %t = ();
    foreach my $dec ( @{ $self->decorators } ) {
        my $fields = $dec->fields;
        my $matched = 0;
        foreach my $src ( sort keys %{ $fields } ) {
            my $doc = $result->document;
            my $val = hash_path_get($src, $doc);
            my $dst = $fields->{$src};
            if ( my $elements = $dec->lookup($doc, $val) ) {
                $matched++;
                $result->add( $src, hash_path_expand( $dst => $elements ));
            }
        }
        last if $matched and $dec->is_final;
    }

    return $result;      # Return the log object
}


1;
__END__

=encoding utf-8

=head1 SYNOPSIS

  use Data::Decorator;

=head1 DESCRIPTION

Data::Decorator is

=head1 SEE ALSO

L<Data::Decorator::Role::PluginLoader>, L<Data::Decorator::Role::Timing>

=cut

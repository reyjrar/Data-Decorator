package Data::Decorator::Role::Plugin;
# ABSTRACT: Common interface for implementing an Data::Decorator plugin

use Moo::Role;
use Types::Standard qw(Bool Int Str);

# VERSION

=head1 SYNOPSIS

Provides the interface to load L<Data::Decorator> plugins in the correct order.


    package MyApp::Decorators::Db::LookUpEmployee;

    use Moo::Role;
    with qw( eris::role::plugin );


=head1 INTERFACE

=head2 decorate

This method will be called everytime a document matches this context.  It receives
a copy of the HashRef it was passed, return the decorated HashRef.

=cut

requires qw(
    decorate
);

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


=attr B<field>

The field in the context of the log to use to use with the C<matcher> to select
a log for parsing.  This is required.

The rules for parsing are:

=over 2

=item B<*>

Reserved for it's use as with C<matcher> set to '*', which forces the context
to be evaluated for every document.

    sub _build_field   { '*' }
    sub _build_matcher { '*' }

Will match every document it's sent.

=item B<_exists_>

Instead of apply the C<matcher> to the value, we'll check it against the key.

Say we wanted to run a reverse DNS check on an IP we could:

    sub _build_field   { '_exists_' }
    sub _build_matcher { /_ip$/ }

Exists supports the following matchers:

=over 2

=item B<String>

Simple string match against the key

=item B<Regex>

Apply the regex to the key

=item B<ArrayRef>

Checks if the key is contained in the array

=back

=item B<String>

The string is considered the name of the field in the document.  That key is
used to check it's value against the C<matcher>.  Using a string are a field name supports
the following C<matcher>'s.

=over 2

=item B<String>

Check if the lowercase string matches the value at the key designated by B<field>, i.e.

    sub _build_field   { 'program' }
    sub _build_matcher { 'sshd' }

This will call C<decorate> on documents with a field 'program' which has the
value 'sshd'.

=item B<Regex>

Checks the value in the field for against the regex.

    sub _build_field   { 'program' }
    sub _build_matcher { /^postfix/ }

This will call C<decorate> on documents with a field 'program' matching the
regex '^postfix'.

=item B<ArrayRef>

Checks the value in the field against all values in the array.


    sub _build_field   { 'program' }
    sub _build_matcher { [qw(sort suricata)] }

This will call C<decorate> on documents with a field 'program' that is either
'snort' or 'suricata'.

=item B<CodeRef>

Check the return value of the code reference passing the value at the field
into the function.

    sub _build_field   { 'src_ip' }
    sub _build_matcher { \&check_bad_ips }

This will call C<decorate> on documents with a field 'src_ip' and call the
C<check_bad_ips()> function with the value in the 'src_ip' field if the sub
routine return true.

=back

=back

=cut

has 'field' => (
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    builder => '_build_field',
);

sub _build_field { 'program' }

=attr B<matcher>

Maybe a B<String>, B<Regex>, B<ArrayRef>, or a B<CodeRef>. See documenation on
L<field> for information on the combinations and how to use them.

=cut

has 'matcher' => (
    is      => 'ro',
    isa     => Defined,
    lazy    => 1,
    builder => '_build_matcher',
);

sub _build_matcher { my ($self) = shift; $self->name; }


=head1 SEE ALSO

L<Data::Decorator>, L<Data::Decorator::Role::PluginLoader>

=cut

1;

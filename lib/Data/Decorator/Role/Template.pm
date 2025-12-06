package Data::Decorator::Role::Template;
# ABSTRACT: Adds a method to enable templating in plugins

use Text::Handlebars;
use Moo::Role;

# VERSION

=attr engine

Returns the L<Text::Handlebars|template engine> object.

=cut

has 'engine' => (
    is => 'lazy',
    isa => InstanceOf['Text::Handlebars'],
    handles => {
        render_template => 'render_string',
    },
);

sub _build_template_engine {
    # TODO: Add helpers maybe?
    Text::Handlebars->new();
}

1;

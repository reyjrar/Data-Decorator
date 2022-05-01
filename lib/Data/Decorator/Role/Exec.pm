package Data::Decorator::Role::Exec;
# ABSTRACT: Adds a method to exec a command and collect it's output

# VERSION

use Capture::Tiny qw(capture);
use Moo::Role;

=method exec_command

Takes a command as a string or an array, executes the command.

If the command returns unsuccessful, we die, otherwise the output is returned.

=cut

sub exec_command {
    my ($self,@command) = @_;

    my ($out,$err,$rc) = capture {
        system(@command);
    };

    if( $rc != 0 ) {
        die sprintf "command failed: command=%s, error=%s",
            join(' ', @command),
            $err;
    }

    return $out;
}

1;

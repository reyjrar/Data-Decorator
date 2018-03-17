package Data::Decorator::Role::Timing;
# ABSTRACT: Provide timing statistics data for tracking

use Moo::Role;
use Statistics::Descriptive;
use Types::Common::Numeric qw( PositiveInt );
use Types::Standard        qw( HashRef InstanceOf );
use namespace::autoclean;

my $_last_minute;

=attr calculator

A L<Statistics::Descriptive::Full> instance for calculating periodic summary
statistics.

=cut

has 'calculator' => (
    is => 'lazy',
    isa => InstanceOf['Statistics::Descriptive::Full'],
);

sub _build_calculator { Statistics::Descriptive::Full->new() }

=attr timing_interval

Seconds between refreshing the statistics in the timing data

=cut

has 'timing_interval' => (
    is      => 'ro',
    isa     => PositiveInt,
    default => sub { 60 },
);

=attr timing_data

Raw statistics for the most recent period

=cut

has 'timing_data' => (
    is      => 'rw',
    isa     => HashRef,
    default => sub { +{} },
);

=attr statistics

Holds the latest statistics calculated from the timing data.

=cut

has 'statistics' => (
    is      => 'rw',
    isa     => HashRef,
    default => sub { +{} },
);

=method add_timing

Passed a HashRef to add to the current timing data

=cut

sub add_timing {
    my ($self,$t) = @_;

    # Record the minute
    my $minute = time;
    $minute -= $minute % 60;
    $_last_minute ||= $minute;

    # Clear Timing Data every interval
    $self->reset_timing_data() if $minute > $_last_minute;

    # add the timing data
    my $timing = $self->timing_data;
    foreach my $stat ( keys %{ $t } ) {
        $timing->{$stat} ||= [];
        push @{ $timing->{$stat} }, $t->{$stat};
    }
}

=method reset_timing_data

Every C<timing_interval>, the statistics are computed and rolled up into
summary statistics and the C<timing_data> is reset.

=cut

sub reset_timing_data {
    my ($self) = @_;

    my $timing = $self->timing_data;
    my $calc   = $self->calculator;

    my %s = ();
    foreach my $k ( keys %{ $timing } ) {
        $calc->clear();
        $calc->add_data( @{ $timing->{$k} } );

        foreach my $stat ( qw(max min mean median) ) {
            ## no critic
            no warnings;
            $s{"$k.$stat"} = $calc->$stat;
            ## use critic
        }
    }
    $self->statistics(\%s);
    $self->timing_data({});
}

no Moo::Role;
1;

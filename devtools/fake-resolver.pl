#!perl
use v5.16;
use warnings;

use Net::DNS::Nameserver;


my %server = (
    port => 8053,
    addr => '127.0.0.1',
);

run_nameserver();

sub run_nameserver {
    my $server = Net::DNS::Nameserver->new(
        LocalAddr => $server{addr},
        LocalPort => $server{port},
        ReplyHandler => sub {
			my @incoming = @_;
			my @names    = qw(qname qclass qtype peerhost query conn);
			my %q = map { shift(@names) => $_ } @incoming;

			my $rcode = "NOERROR";
			my (@ans,@auth,@add);

			my %answers = qw(
				PTR localhost.localdomain
			);

			my $name = lc $q{qname};
			my $answer = $answers{$q{qtype}} || 'UNKNOWN';
			my $response = "$q{qname} $q{qclass} $q{qtype} $answer";
			push @ans, Net::DNS::RR->new($response);
            printf "Responding with: %s\n", $response;
			return ( $rcode, \@ans, \@auth, \@add, );
        },
    );
    say "Server running on $server{addr}:$server{port}";
	$server->main_loop;
}

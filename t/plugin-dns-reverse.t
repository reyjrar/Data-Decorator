use strict;
use warnings;

use Data::Decorator;
use Test::More tests => 4;
use Test::SharedFork;
use Net::DNS::Nameserver;

my %server = (
    # Select a random port
    port => int(rand(1024) + 8000),
    addr => '127.0.0.1',
);

# Fork a DNS server for testing
my $pid = fork();
if( $pid ) {
    run_nameserver();
}
else {
    sleep 1;
    run_tests();
}

sub run_tests {
	my $dd = Data::Decorator->new(
		decorators => {
            rdns => {
                plugin => 'DNS::Reverse',
                fields => {
                    src_ip => 'src_rdns',
                },
                config => {
                    no_cache => 1,
                    resolver => {
                        nameservers => [$server{addr}],
                        port => $server{port},
                    }
                }
            }
		}
	);
    ok($dd, "loaded object");

    my $doc = { foo => 1, src_ip => '8.8.8.8' };
    my $result = $dd->decorate($doc);

    is_deeply( $result->document, { %$doc, src_rdns => 'localhost.localdomain.' },
        "rdns plugin is working as expected"
    );
}

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
			push @ans, Net::DNS::RR->new("$q{qname} $q{qclass} $q{qtype} $answer");
			return ( $rcode, \@ans, \@auth, \@add, );
        },
    );
    ok($server, "server created");
	$server->loop_once;
    pass("handled response");
    sleep 1;
}

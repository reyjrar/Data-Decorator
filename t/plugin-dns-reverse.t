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

# Number of queries expected, controls the name server loop
my $queries = 2;

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
                expand_hash_keys => 1,
                fields => {
                    src_ip => 'src_rdns',
                    "dest.ip" => "dest.rdns",
                },
                no_cache => 1,
                config => {
                    resolver => {
                        nameservers => [$server{addr}],
                        port => $server{port},
                    }
                }
            }
		}
	);
    ok($dd, "loaded object");

    my $doc = { foo => 1, src_ip => '8.8.8.8', dest => { ip => "1.2.3.4" } };
    my $result = $dd->decorate($doc);

    my $expected = { %$doc, src_rdns => 'localhost.localdomain.', };
    $expected->{dest}{rdns} = 'localhost.localdomain.';
    is_deeply( $result->document, $expected,
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
	$server->loop_once for 1 .. $queries;
    pass("handled response");
    sleep 1;
}

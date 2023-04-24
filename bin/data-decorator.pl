#!perl
# PODNAME: data-decorator.pl
# ABSTRACT: Apply a local set of decorator rules to a stream of NDJSON
use v5.16;
use warnings;

use CLI::Helpers qw(:output);
use Data::Decorator;
use Getopt::Long::Descriptive;
use JSON::MaybeXS;

my ($opt,$usage) = describe_options("%c %o",
    ['config-file|config|c=s', "Override the config file for Data::Decorator"],
    [],
    ['help', "Display this message", { shortcircuit => 1 }],
);

if( $opt->help ) {
    print $usage->text;
    exit 0;
}

my $dd = Data::Decorator->new(
    $opt->config_file ? ( config_file => $opt->config_file ) : (),
);
my $json = JSON->new->utf8->canonical;

debug({color=>"yellow"}, sprintf "loaded config from %s", $dd->config_file || 'defaults');
debug_var({json=>1,color=>"cyan"}, $dd->decorator_config);

while(<<>>) {
    my $doc = eval { decode_json($_) };
    next unless $doc;

    my $result = $dd->decorate($doc);
    output({color=>"white",data=>1}, encode_json($result->document));
}

#!perl
# PODNAME: data-decorator.pl
# ABSTRACT: Apply a local set of decorator rules to a stream of NDJSON
use v5.16;

use Const::Fast;
use Getopt::Long::Descriptive;
use JSON::MaybeXS;

my ($opt,$usage) = describe_options("%c %o",
    [],
    ['help', "Display this message", { shortcircuit => 1 }],
);

if( $opt->help ) {
    print $usage->text;
    exit 0;
}


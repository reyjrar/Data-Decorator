use strict;
use Test::Deep;
use Test::More;
use Data::Decorator::Result;

my $doc = {
    dst_ip => '8.8.8.8',
    src_ip => '127.0.0.1',
};

my $result = Data::Decorator::Result->new(
    document => $doc,
);

# Ensure document storage works
cmp_deeply( $doc, $result->document, "stored the document" );

# Make sure adding fields works
my %src = ( src_rdns => 'localhost.localdomain' );
$result->add( src_ip => \%src );
cmp_deeply( $result->document, { %{ $doc }, %src }, "added field to the result document");

# Check for added_fields
cmp_deeply( $result->added_fields, [qw(src_rdns)], "added fields recorded" );

# Add another field
my %dst = ( dst_rdns => 'ns.google.com' );
$result->add( dst_ip => \%dst );
cmp_deeply( $result->document, { %{ $doc }, %src, %dst }, "added second field to the result document");

# Check for added_fields
cmp_deeply( $result->added_fields, [qw(dst_rdns src_rdns)], "added fields recorded for second field" );
cmp_deeply( $result->added_fields('src_ip'), [qw(src_rdns)], "looking up src_ip's added fields returns correctly" );

# Add more than one field
my %src2 = (
    src_geoip => { city => 'New York', country => 'US' },
    src_iptype => { type => 'isp', confidence => 0.8 },
);

$result->add( src_ip => \%src2 );
cmp_deeply( $result->document, { %{ $doc }, %src, %src2, %dst }, "added third set of fields to the result document");

cmp_deeply( $result->added_fields('src_ip'), [
        qw(src_rdns src_geoip.city src_geoip.country src_iptype.confidence src_iptype.type
        )
    ],
    "looking up src_ip's added fields returns correctly"
);

done_testing;

# Data::Decorator Design

Overview of how to use and layout the code for Data::Decorator.

## es-search.pl ideas

```yaml
# .data-decorator.yaml
---
rdns:
  plugin: DNS::Reverse
  cache: 10m
  fields:
    dst_ip: dst_rdns
    src_ip: src_rdns

geoip:
  plugin: GeoIP
  cache: 24h
  fields:
    dst_ip: dst_geoip
    src_ip: src_geoip

username:
  plugin: SQL
  cache: 24h
  config:
    connection:
      dsn: dbi:Pg:hostname=localhost
      username: test
      password: testing
  query: SELECT user_name FROM users WHERE user_id = ?
  params:
    - user_id
  fields:
    user_id: user_name
  
my_api:
  plugin: HTTP::API
  cache: 24h
  config:
    url: https://myapi.org/v1/ip/reputation
    headers:
      X-Token: 187519826512859125
      X-Client-ID: 124214
    select: ip.reputation.score
  fields:
    src_ip: src_ip_score
```

```yaml
# es-utils.yaml
---
meta:
  access:
    decorate:
      - rdns
      - geoip
```

```perl
# What this looks like in code

my $decorator = Data::Decortator->new(
    decorators => $hashref,
);

my $result = $decorator->decorate( $document );

$result->added_fields(@optional_keys);

$result->add( src_ip => { src_rdns => 'bob.google.com.' } );
```

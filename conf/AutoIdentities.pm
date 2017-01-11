use strict;
use warnings;

use Sys::Hostname;

use SiteDefs;

$SiteDefs::ENSEMBL_IDENTITIES = [
  sub {
    my $host = Sys::Hostname::hostname;
    my ($prefix, $org) = split /\./, $host;
    return [ $prefix, $org, $host ];
  },
];

1;

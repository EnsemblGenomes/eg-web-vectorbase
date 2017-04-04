package ND::Live::SiteDefs;
use strict;


sub update_conf {

  $SiteDefs::ENSEMBL_SERVERNAME  = 'www.vectorbase.org';
  $SiteDefs::ENSEMBL_BASE_URL    = 'https://www.vectorbase.org';
  $SiteDefs::VECTORBASE_BASE_URL = 'https://www.vectorbase.org';

  $SiteDefs::ENSEMBL_PROXY_PORT = 80;
}

1;

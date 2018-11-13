my $BASE = $SiteDefs::ENSEMBL_SERVERROOT;

my $common = [
  'ND'                      => $BASE.'/eg-web-vectorbase/conf-plugins/nd',
  'EG::Vectorbase'          => $BASE.'/eg-web-vectorbase',
  'EG::Common'              => $BASE.'/eg-web-common',
  'EnsEMBL::Genoverse'      => $BASE.'/public-plugins/genoverse',
  'EnsEMBL::Widgets'        => $BASE.'/public-plugins/widgets',
  'EnsEMBL::Tools_hive'     => $BASE.'/public-plugins/tools_hive',
  'EnsEMBL::Tools'          => $BASE.'/public-plugins/tools',
  'EnsEMBL::Memcached'      => $BASE.'/public-plugins/memcached',
  'EnsEMBL::Docs'           => $BASE.'/public-plugins/docs',
];

# currently using same plugins in pre and live
# but we could have different plugins if needed
$SiteDefs::ENSEMBL_AUTOPLUGINS = {
  "fry"    => [ @$common ],
  "edward" => [ @$common ],
};

1;

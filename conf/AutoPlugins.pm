my $BASE = $SiteDefs::ENSEMBL_SERVERROOT;

my $common = [
  'EG::Vectorbase'          => $BASE.'/eg-web-vectorbase',
  'EG::Common'              => $BASE.'/eg-web-common',
  'EnsEMBL::Genoverse'      => $BASE.'/public-plugins/genoverse',
  'EnsEMBL::Widgets'        => $BASE.'/public-plugins/widgets',
  'EnsEMBL::Tools_hive'     => $BASE.'/public-plugins/tools_hive',
  'EnsEMBL::Tools'          => $BASE.'/public-plugins/tools',
  'EnsEMBL::Memcached'      => $BASE.'/public-plugins/memcached',
  'EnsEMBL::Docs'           => $BASE.'/public-plugins/docs',
];

$SiteDefs::ENSEMBL_AUTOPLUGINS = {

  "unix:gunpowder" => [
    'MyPlugins'         => $BASE.'/my-plugins',
    'VB::Hinxton::Prod' => $BASE.'/eg-web-ensembl-configs/vb-hx-prod',         
    'EBI::Hinxton'      => $BASE.'/eg-web-ensembl-configs/eg-hx',    
    @$common,
  ],

  "unix:fry" => [
    'ND::Pre'  => $BASE.'/eg-web-vectorbase/conf-plugins/nd-pre',
    @$common,
  ],

  "unix:edward" => [
    'ND::Live' => $BASE.'/eg-web-vectorbase/conf-plugins/nd-live',
    @$common,
  ],

};

1;

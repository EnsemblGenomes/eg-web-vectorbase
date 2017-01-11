use strict;
my $BASE = $SiteDefs::ENSEMBL_SERVERROOT;

$SiteDefs::ENSEMBL_PLUGINS = [
  'MyPlugins'               => $BASE.'/my-plugins',
  
  # Plugins for EBI development environment
  #'VB::Hinxton::ArchiveProd' => $BASE.'/eg-web-ensembl-configs/vb-hx-archive-prod', 
  #'VB::Hinxton::Prod'        => $BASE.'/eg-web-ensembl-configs/vb-hx-prod',         
  #'EBI::Hinxton'             => $BASE.'/eg-web-ensembl-configs/eg-hx',              
  
  'EG::Vectorbase'          => $BASE.'/eg-web-vectorbase',
  'EG::Common'              => $BASE.'/eg-web-common',
  'EnsEMBL::Genoverse'      => $BASE.'/public-plugins/genoverse',
  'EnsEMBL::Widgets'        => $BASE.'/public-plugins/widgets',
  'EnsEMBL::Tools_hive'     => $BASE.'/public-plugins/tools_hive',
  'EnsEMBL::Tools'          => $BASE.'/public-plugins/tools',
  'EnsEMBL::Memcached'      => $BASE.'/public-plugins/memcached',
  'EnsEMBL::Docs'           => $BASE.'/public-plugins/docs',
];

1;

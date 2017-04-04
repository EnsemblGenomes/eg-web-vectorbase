package EG::Vectorbase::SiteDefs;
use strict;
use Sys::Hostname;

sub update_conf {

  $SiteDefs::SITE_RELEASE_VERSION = '1704';
  $SiteDefs::SITE_RELEASE_DATE    = 'April 2017';
  $SiteDefs::VECTORBASE_VERSION   = 'VB-2017-04';

  $SiteDefs::ENSEMBL_PORT = 8080; 
  $SiteDefs::APACHE_BIN   = '/usr/sbin/httpd';
  $SiteDefs::APACHE_DIR   = '/etc/httpd';
  $SiteDefs::SAMTOOLS_DIR = '/nfs/public/rw/ensembl/samtools';
  $SiteDefs::MWIGGLE_DIR  = '/nfs/public/rw/ensembl/tools/mwiggle/';
  $SiteDefs::HTSLIB_DIR   = '/nfs/public/rw/ensembl/tools/htslib/';
  $SiteDefs::R2R_BIN      = '/nfs/public/rw/ensembl/tools/R2R-1.0.5/src/r2r';
  
  $SiteDefs::ENSEMBL_PRIMARY_SPECIES   = 'Anopheles_gambiae';
  $SiteDefs::ENSEMBL_SECONDARY_SPECIES ='Aedes_aegypti';

  $SiteDefs::ENSEMBL_DATASETS = [qw(
    Aedes_aegypti
    Aedes_albopictus
    Anopheles_albimanus
    Anopheles_arabiensis
    Anopheles_atroparvus
    Anopheles_christyi
    Anopheles_coluzzii
    Anopheles_culicifacies
    Anopheles_darlingi
    Anopheles_dirus
    Anopheles_epiroticus
    Anopheles_farauti
    Anopheles_funestus
    Anopheles_gambiae
    Anopheles_gambiaeS
    Anopheles_maculatus
    Anopheles_melas
    Anopheles_merus
    Anopheles_minimus
    Anopheles_quadriannulatus
    Anopheles_sinensis
    Anopheles_sinensisC
    Anopheles_stephensi
    Anopheles_stephensiI
    Biomphalaria_glabrata
    Cimex_lectularius
    Culex_quinquefasciatus
    Glossina_austeni
    Glossina_brevipalpis
    Glossina_fuscipes
    Glossina_morsitans
    Glossina_pallidipes
    Glossina_palpalis
    Ixodes_scapularis
    Lutzomyia_longipalpis
    Musca_domestica
    Pediculus_humanus
    Phlebotomus_papatasi
    Rhodnius_prolixus
    Sarcoptes_scabiei
    Stomoxys_calcitrans
  )];

  @SiteDefs::ENSEMBL_PERL_DIRS    = (
    $SiteDefs::ENSEMBL_WEBROOT.'/perl',
    $SiteDefs::ENSEMBL_SERVERROOT.'/eg-plugins/common/perl',
    $SiteDefs::ENSEMBL_SERVERROOT.'/eg-plugins/vectorbase/perl',
  );

  $SiteDefs::ENSEMBL_SITENAME       = 'VectorBase';
  $SiteDefs::ENSEMBL_SITE_NAME      = 'VectorBase';
  $SiteDefs::ENSEMBL_SITETYPE       = 'VectorBase';
  $SiteDefs::ENSEMBL_HELPDESK_EMAIL = 'info@vectorbase.org';
  $SiteDefs::ENSEMBL_SERVERADMIN    = 'webmaster@vectorbase.org';
  $SiteDefs::ENSEMBL_MAIL_SERVER    = 'smtp.vectorbase.org';
  $SiteDefs::SITE_FTP               = '/downloads';
  
  $SiteDefs::VECTORBASE_SEARCH_SITE        = $SiteDefs::ENSEMBL_BASE_URL;
  $SiteDefs::VECTORBASE_EXPRESSION_BROWSER = $SiteDefs::ENSEMBL_BASE_URL . '/expression-browser';
  $SiteDefs::VECTORBASE_SAMPLE_SEARCH_URL  = $SiteDefs::ENSEMBL_BASE_URL . '/popbio/sample-explorer';
  #$SiteDefs::VECTORBASE_SAMPLE_SEARCH_URL  = 'http://gunpowder.ebi.ac.uk:10971/popbio/sample-explorer';
  #$SiteDefs::VECTORBASE_SAMPLE_SEARCH_URL   = 'http://gunpowder.ebi.ac.uk:10971';
  
  $SiteDefs::ENSEMBL_LOGINS = 0;
  $siteDefs::UDC_CACHEDIR = '/tmp';

  $SiteDefs::ENSEMBL_BLAST_ENABLED = 0;

  # Assembly converter
  $SiteDefs::ENSEMBL_AC_ENABLED          = 1;
  $SiteDefs::ASSEMBLY_CONVERTER_BIN_PATH = '/nfs/public/rw/ensembl/python/bin/CrossMap.py';
  $SiteDefs::ENSEMBL_CHAIN_FILE_DIR      = '/vectorbase/data/assembly_converter';
  
  # VEP    
  $SiteDefs::ENSEMBL_VEP_ENABLED   = 1;
  $SiteDefs::ENSEMBL_VEP_CACHE_DIR = undef; # no cache
  $SiteDefs::ENSEMBL_VEP_FILTER_SCRIPT_OPTIONS = {
    '-host' => 'localhost',
    '-port' => '3306',
    '-user' => 'ensro',
  };
  $SiteDefs::ENSEMBL_VEP_SCRIPT_DEFAULT_OPTIONS = {
    'host' => 'localhost',
    'port' => '3306',
    'user' => 'ensro',
    'fork' => 4,
  };
}

1;


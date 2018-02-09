package EG::Vectorbase::SiteDefs;
use strict;
use Sys::Hostname;

sub update_conf {

  $SiteDefs::SITE_RELEASE_VERSION = '1802';
  $SiteDefs::SITE_RELEASE_DATE    = 'February 2018';
  $SiteDefs::VECTORBASE_VERSION   = 'VB-2018-02';

  $SiteDefs::ENSEMBL_PORT = 8080; 
  $SiteDefs::APACHE_BIN   = '/usr/sbin/httpd';
  $SiteDefs::APACHE_DIR   = '/etc/httpd';
  $SiteDefs::SAMTOOLS_DIR = '/nfs/public/rw/ensembl/samtools';
  $SiteDefs::MWIGGLE_DIR  = '/nfs/public/rw/ensembl/tools/mwiggle/';
  $SiteDefs::HTSLIB_DIR   = '/nfs/public/rw/ensembl/tools/htslib/';
  $SiteDefs::R2R_BIN      = '/nfs/public/rw/ensembl/tools/R2R-1.0.5/src/r2r';
  
  $SiteDefs::ENSEMBL_PRIMARY_SPECIES   = 'Anopheles_gambiae';
  $SiteDefs::ENSEMBL_SECONDARY_SPECIES = 'Aedes_aegypti_lvpagwg';

  $SiteDefs::PRODUCTION_NAMES = [qw(
    aedes_aegypti_lvp
    aedes_aegypti_lvpagwg
    aedes_albopictus
    anopheles_albimanus
    anopheles_arabiensis
    anopheles_atroparvus
    anopheles_christyi
    anopheles_coluzzii
    anopheles_culicifacies
    anopheles_darlingi
    anopheles_dirus
    anopheles_epiroticus
    anopheles_farauti
    anopheles_funestus
    anopheles_gambiae
    anopheles_gambiae_pimperena
    anopheles_maculatus
    anopheles_melas
    anopheles_merus
    anopheles_minimus
    anopheles_quadriannulatus
    anopheles_sinensis
    anopheles_sinensis_china
    anopheles_stephensi
    anopheles_stephensi_indian
    biomphalaria_glabrata
    cimex_lectularius
    culex_quinquefasciatus
    glossina_austeni
    glossina_brevipalpis
    glossina_fuscipes
    glossina_morsitans
    glossina_pallidipes
    glossina_palpalis
    ixodes_scapularis
    lutzomyia_longipalpis
    musca_domestica
    pediculus_humanus
    phlebotomus_papatasi
    rhodnius_prolixus
    sarcoptes_scabiei
    stomoxys_calcitrans
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

  $SiteDefs::GRAPHIC_TTF_PATH = '/nfs/public/rw/ensembl/fonts/truetype/msttcorefonts/';
}

1;


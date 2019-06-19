package EG::Vectorbase::SiteDefs;
use strict;
use Sys::Hostname;
use Cwd qw(abs_path);
use List::MoreUtils qw(uniq);

sub update_conf {



  my $release = "vb_".$SiteDefs::ENSEMBL_VERSION;

  $SiteDefs::SITE_RELEASE_VERSION = '1906';
  $SiteDefs::SITE_RELEASE_DATE    = 'June 2019';
  $SiteDefs::VECTORBASE_VERSION   = 'VB-2019-06';

  $SiteDefs::ENSEMBL_PORT = 8080; 

  $SiteDefs::ENSEMBL_TMP_ROOT               = '/ebi/nobackup';
  $SiteDefs::ENSEMBL_USERDATA_ROOT          = '/ebi/incoming';
  $SiteDefs::DATAFILE_ROOT                  = '/ebi/ensweb-data';


  $SiteDefs::ENSEMBL_TMP_DIR                = defer { $SiteDefs::ENSEMBL_TMP_ROOT . "/" . $SiteDefs::VECTORBASE_VERSION };
  $SiteDefs::ENSEMBL_SYS_DIR                = defer { "$SiteDefs::ENSEMBL_TMP_DIR/server" };
  $SiteDefs::ENSEMBL_USERDATA_DIR           = defer { $SiteDefs::ENSEMBL_USERDATA_ROOT.'/vb' };
  $SiteDefs::DATAFILE_BASE_PATH             = undef; # not used for EG as VCF files are stored on remote ftp/http servers 

  $SiteDefs::ENSEMBL_MINIFIED_FILES_PATH    = defer { "$SiteDefs::ENSEMBL_SYS_DIR/minified" }; 

  $SiteDefs::ENSEMBL_PRIMARY_SPECIES   = 'Anopheles_gambiae';
  $SiteDefs::ENSEMBL_SECONDARY_SPECIES = 'Aedes_aegypti_lvpagwg';

  $SiteDefs::PRODUCTION_NAMES = [qw(
    aedes_aegypti_lvpagwg
    aedes_albopictus
    anopheles_albimanus
    anopheles_arabiensis
    anopheles_atroparvus
    anopheles_christyi
    anopheles_coluzzii
    anopheles_coluzzii_ngousso
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
    ixodes_scapularis_ise6
    lutzomyia_longipalpis
    leptotrombidium_deliense
    musca_domestica
    pediculus_humanus
    phlebotomus_papatasi
    rhodnius_prolixus
    sarcoptes_scabiei
    stomoxys_calcitrans
  )];


  $SiteDefs::ENSEMBL_SITENAME       = 'VectorBase';
  $SiteDefs::ENSEMBL_SITE_NAME      = 'VectorBase';
  $SiteDefs::ENSEMBL_SITETYPE       = 'VectorBase';
  $SiteDefs::ENSEMBL_HELPDESK_EMAIL = 'info@vectorbase.org';
  $SiteDefs::ENSEMBL_SERVERADMIN    = 'webmaster@vectorbase.org';
  $SiteDefs::ENSEMBL_MAIL_SERVER    = 'smtp.vectorbase.org';

  $SiteDefs::VECTORBASE_SEARCH_SITE        = $SiteDefs::ENSEMBL_BASE_URL;
  $SiteDefs::VECTORBASE_EXPRESSION_BROWSER = $SiteDefs::ENSEMBL_BASE_URL . '/expression-browser';
  $SiteDefs::VECTORBASE_SAMPLE_SEARCH_URL  = $SiteDefs::ENSEMBL_BASE_URL . '/popbio/sample-explorer';
  
  $SiteDefs::ENSEMBL_LOGINS = 0;

  $SiteDefs::ENSEMBL_BLAST_ENABLED = 0;

 # Assembly converter
  $SiteDefs::ENSEMBL_AC_ENABLED          = 1;
  $SiteDefs::ASSEMBLY_CONVERTER_BIN_PATH = defer { $SiteDefs::SHARED_SOFTWARE_PATH.'/paths/CrossMap.py' };
  $SiteDefs::ENSEMBL_CHAIN_FILE_DIR      = defer { $SiteDefs::DATAFILE_ROOT.'/tools/assembly_converter/'};
  

# VEP    
  $SiteDefs::ENSEMBL_VEP_ENABLED   = 1;
  $SiteDefs::ENSEMBL_VEP_CACHE_DIR = undef; # no cache
  $SiteDefs::ENSEMBL_VEP_FILTER_SCRIPT_OPTIONS = {
    '-host' => '127.0.0.1',
    '-port' => '3306',
    '-user' => 'ensro',
  };
  $SiteDefs::ENSEMBL_VEP_SCRIPT_DEFAULT_OPTIONS = {
    'host' => '127.0.0.1',
    'port' => '3306',
    'user' => 'ensro',
    'fork' => 4,
  };

  
}

1;


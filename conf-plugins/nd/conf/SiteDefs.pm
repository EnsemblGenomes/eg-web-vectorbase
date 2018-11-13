package ND::Pre::SiteDefs;
use strict;
use Sys::Hostname;

sub update_conf {

  my $hostname = hostname;

  $SiteDefs::VB_PREFIX           = $hostname =~ /fry/ ? 'pre' : 'www';
  $SiteDefs::ENSEMBL_SERVERNAME  = "$SiteDefs::VB_PREFIX.vectorbase.org";
  $SiteDefs::ENSEMBL_BASE_URL    = "https://$SiteDefs::VB_PREFIX.vectorbase.org";
  $SiteDefs::VECTORBASE_BASE_URL = "https://$SiteDefs::VB_PREFIX.vectorbase.org";
  $SiteDefs::ENSEMBL_PROXY_PORT  = 80;

  $SiteDefs::SHARED_SOFTWARE_PATH           = "/ebi/ensweb-software/sharedsw/$release";
  $SiteDefs::SHARED_SOFTWARE_BIN_PATH       = defer { join ':', uniq($SiteDefs::SHARED_SOFTWARE_PATH.'/linuxbrew/bin', split(':', $ENV{'PATH'} || ())) };
  $SiteDefs::ENSEMBL_SETENV->{'PATH'}       = 'SHARED_SOFTWARE_BIN_PATH';

  $SiteDefs::APACHE_BIN                     = defer { $SiteDefs::SHARED_SOFTWARE_PATH.'/paths/apache/httpd' };
  $SiteDefs::APACHE_DIR                     = defer { $SiteDefs::SHARED_SOFTWARE_PATH.'/paths/apache/' };
  $SiteDefs::BIOPERL_DIR                    = defer { $SiteDefs::SHARED_SOFTWARE_PATH.'/paths/bioperl/' };
  $SiteDefs::VCFTOOLS_PERL_LIB              = defer { $SiteDefs::SHARED_SOFTWARE_PATH.'/paths/vcftools_perl_lib/' };
  $SiteDefs::TABIX                          = defer { $SiteDefs::SHARED_SOFTWARE_PATH.'/paths/tabix' };
  $SiteDefs::SAMTOOLS                       = defer { $SiteDefs::SHARED_SOFTWARE_PATH.'/paths/samtools' };
  $SiteDefs::BGZIP                          = defer { $SiteDefs::SHARED_SOFTWARE_PATH.'/paths/bgzip' };
  $SiteDefs::HTSLIB_DIR                     = defer { $SiteDefs::SHARED_SOFTWARE_PATH.'/paths/htslib' };
  $SiteDefs::R2R_BIN                        = defer { $SiteDefs::SHARED_SOFTWARE_PATH.'/paths/r2r' };
  $SiteDefs::HUBCHECK_BIN                   = defer { $SiteDefs::SHARED_SOFTWARE_PATH.'/utils/hubCheck' };
  $SiteDefs::ENSEMBL_JAVA                   = defer { $SiteDefs::SHARED_SOFTWARE_PATH.'/paths/java' };
  $SiteDefs::ENSEMBL_EMBOSS_PATH            = defer { $SiteDefs::SHARED_SOFTWARE_PATH.'/paths/emboss' };   #AlignView
  $SiteDefs::ENSEMBL_WISE2_PATH             = defer { $SiteDefs::SHARED_SOFTWARE_PATH.'/paths/genewise' }; #AlignView
  $SiteDefs::THOUSANDG_TOOLS_DIR            = defer { $SiteDefs::SHARED_SOFTWARE_PATH.'/1000G-tools' }; #location of all 1000G tools runnable and scripts
  $SiteDefs::GRAPHIC_TTF_PATH               = defer { $SiteDefs::SHARED_SOFTWARE_PATH.'/fonts/' };
  $SiteDefs::MWIGGLE_DIR                    = '/nfs/public/rw/ensembl/tools/mwiggle/';
}

1;

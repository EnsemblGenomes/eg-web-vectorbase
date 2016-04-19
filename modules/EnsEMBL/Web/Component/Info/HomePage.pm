# $Id: HomePage.pm,v 1.8 2013-12-03 12:44:26 nl2 Exp $

package EnsEMBL::Web::Component::Info::HomePage;

use strict;

sub _assembly_text {
  my $self             = shift;
  my $hub              = $self->hub;
  my $species_defs     = $hub->species_defs;
  my $species          = $hub->species;
  my $name             = $species_defs->SPECIES_COMMON_NAME;
  my $img_url          = $self->img_url;
  my $sample_data      = $species_defs->SAMPLE_DATA;
  my $ensembl_version  = $species_defs->SITE_RELEASE_VERSION;
  my $current_assembly = $species_defs->ASSEMBLY_NAME;
  my $accession        = $species_defs->ASSEMBLY_ACCESSION;
  my $source           = $species_defs->ASSEMBLY_ACCESSION_SOURCE || 'NCBI';
  my $source_type      = $species_defs->ASSEMBLY_ACCESSION_TYPE;
 #my %archive          = %{$species_defs->get_config($species, 'ENSEMBL_ARCHIVES') || {}};
  my %assemblies       = %{$species_defs->get_config($species, 'ASSEMBLIES') || {}};
  my $previous         = $current_assembly;

  my $html = '<div class="homepage-icon">';

  if (@{$species_defs->ENSEMBL_CHROMOSOMES || []}) {
    $html .= qq(<a class="nodeco _ht" href="/$species/Location/Genome" title="Go to $name karyotype"><img src="${img_url}96/karyotype.png" class="bordered" /><span>View karyotype</span></a>);
  }

  my $region_text = $sample_data->{'LOCATION_TEXT'};
  my $region_url  = $species_defs->species_path . '/Location/View?r=' . $sample_data->{'LOCATION_PARAM'};

  $html .= qq(<a class="nodeco _ht" href="$region_url" title="Go to $region_text"><img src="${img_url}96/region.png" class="bordered" /><span>Example region</span></a>);
  $html .= '</div>'; #homepage-icon

## VB
  my $vb_species = $hub->database('core')->get_MetaContainer->single_value_by_key('species.vectorbase_name');
  my $assembly_display_name = $species_defs->ASSEMBLY_DISPLAY_NAME;
  (my $strain = lc($species_defs->SPECIES_STRAIN)) =~ s/\s+/-/g;
  my $assembly = sprintf( 
    '<a href="/organisms/%s/%s/%s">%s</a>', 
    lc($vb_species), 
    $strain,
    lc($assembly_display_name), 
    $assembly_display_name
  );
## VB
  
  
  $html .= "<h2>Genome assembly: $assembly</h2>";
  $html .= qq(<p><a href="/$species/Info/Annotation/#assembly" class="nodeco"><img src="${img_url}24/info.png" alt="" class="homepage-link" />More information and statistics</a></p>);

  # Link to FTP site
  if ($species_defs->ENSEMBL_FTP_URL) {
    my $ftp_url;
    if ($self->is_bacteria) {
      $ftp_url = sprintf '%s/release-%s/fasta/%s_collection/%s/dna/', $species_defs->ENSEMBL_FTP_URL, $ensembl_version, $species_defs->SPECIES_DATASET, lc $species;
    }
    else {
      $ftp_url = sprintf '%s/release-%s/fasta/%s/dna/', $species_defs->ENSEMBL_FTP_URL, $ensembl_version, lc $species;
    }
    $html .= qq(<p><a href="$ftp_url" class="nodeco"><img src="${img_url}24/download.png" alt="" class="homepage-link" />Download DNA sequence</a> (FASTA)</p>);
  }
  
  # Link to assembly mapper
  my $mappings = $species_defs->ASSEMBLY_MAPPINGS;
  if ($mappings && ref($mappings) eq 'ARRAY') {
    my $am_url = $hub->url({'type' => 'UserData', 'action' => 'SelectFeatures'});
    $html .= qq(<p><a href="$am_url" class="modal_link nodeco"><img src="${img_url}24/tool.png" class="homepage-link" />Convert your data to $assembly coordinates</a></p>);
  }

#EG no old assemblies
 ## PREVIOUS ASSEMBLIES
 #my @old_archives;
 #
 ## Insert dropdown list of old assemblies
 #foreach my $release (reverse sort keys %archive) {
 #  next if $release == $ensembl_version;
 #  next if $assemblies{$release} eq $previous;

 #  push @old_archives, {
 #    url      => sprintf('http://%s.archive.ensembl.org/%s/', lc $archive{$release},           $species),
 #    assembly => "$assemblies{$release}",
 #    release  => (sprintf '(%s release %s)',                  $species_defs->ENSEMBL_SITETYPE, $release),
 #  };

 #  $previous = $assemblies{$release};
 #}

 ## Combine archives and pre
 #my $other_assemblies;
 #if (@old_archives) {
 #  $other_assemblies .= join '', map qq(<li><a href="$_->{'url'}" class="nodeco">$_->{'assembly'}</a> $_->{'release'}</li>), @old_archives;
 #}

 #my $pre_species = $species_defs->get_config('MULTI', 'PRE_SPECIES');
 #if ($pre_species->{$species}) {
 #  $other_assemblies .= sprintf('<li><a href="http://pre.ensembl.org/%s/" class="nodeco">%s</a> (Ensembl pre)</li>', $species, $pre_species->{$species}[1]);
 #}

 #if ($other_assemblies) {
 #  $html .= qq(
 #    <h3 style="color:#808080;padding-top:8px">Other assemblies</h3>
 #    <ul>$other_assemblies</ul>
 #  );
 #}

  return $html;
}

sub _variation_text {
  my $self         = shift;
  my $hub          = $self->hub;
  my $species_defs = $hub->species_defs;
  my $species      = $hub->species;
  my $img_url      = $self->img_url;
  my $sample_data  = $species_defs->SAMPLE_DATA;
  my $ensembl_version = $species_defs->SITE_RELEASE_VERSION;
  my $display_name    = $species_defs->SPECIES_SCIENTIFIC_NAME;
  my $html;

  if ($hub->database('variation')) {
    $html .= '<div class="homepage-icon">';

    if ($sample_data->{'VARIATION_PARAM'}) {
      my $var_url  = $species_defs->species_path . '/Variation/Explore?v=' . $sample_data->{'VARIATION_PARAM'};
      my $var_text = $sample_data->{'VARIATION_TEXT'};
      $html .= qq(
        <a class="nodeco _ht" href="$var_url" title="Go to variant $var_text"><img src="${img_url}96/variation.png" class="bordered" /><span>Example variant</span></a>
      );
    }

    if ($sample_data->{'PHENOTYPE_PARAM'}) {
      my $phen_text = $sample_data->{'PHENOTYPE_TEXT'};
      my $phen_url  = $species_defs->species_path . '/Phenotype/Locations?ph=' . $sample_data->{'PHENOTYPE_PARAM'};
      $html .= qq(<a class="nodeco _ht" href="$phen_url" title="Go to phenotype $phen_text"><img src="${img_url}96/phenotype.png" class="bordered" /><span>Example phenotype</span></a>);
    }

    if ($sample_data->{'STRUCTURAL_PARAM'}) {
      my $struct_text = $sample_data->{'STRUCTURAL_TEXT'};
      my $struct_url = $species_defs->species_path .'/StructuralVariation/Explore?sv='.$sample_data->{'STRUCTURAL_PARAM'};
      $html .= qq(<a class="nodeco _ht"  href="$struct_url" title="Go to structural variant $struct_text"><img src="${img_url}96/struct_var.png" class="bordered" /><span>Example structural variant</span></a>);
    }

    $html .= '</div>';
    $html .= '<h2>Variation</h2><p><strong>What can I find?</strong> Short sequence variants';
    if ($species_defs->databases->{'DATABASE_VARIATION'}{'STRUCTURAL_VARIANT_COUNT'}) {
      $html .= ' and longer structural variants';
    }
    if ($sample_data->{'PHENOTYPE_PARAM'}) {
      $html .= '; disease and other phenotypes';
    }
    $html .= '.</p>';

    if ($self->_other_text('variation', $species)) {
      $html .= qq(<p><a href="/$species/Info/Annotation#variation" class="nodeco"><img src="${img_url}24/info.png" alt="" class="homepage-link" />More about variation in $display_name</a></p>);
    }

    my $site = $species_defs->ENSEMBL_SITETYPE;
    $html .= qq(<p><a href="http://ensemblgenomes.org/info/data/variation" class="nodeco"><img src="${img_url}24/info.png" alt="" class="homepage-link" />More about variation in $site</a></p>);

## VB-4686 link to phenotype list
    $html .= qq(<p><a href="/$species/Phenotype/All" class="nodeco"><img src="${img_url}24/info.png" alt="" class="homepage-link" />List of Phenotypes</a></p>);
##

    if ($species_defs->ENSEMBL_FTP_URL) {
      my @links;
      foreach my $format (qw/gvf vcf/){
        push(@links, sprintf('<a href="%s/release-%s/%s/%s/" class="nodeco _ht" title="Download (via FTP) all <em>%s</em> variants in %s format">%s</a>', $species_defs->ENSEMBL_FTP_URL, $ensembl_version, $format, lc $species, $display_name, uc $format,uc $format));
      }
      push(@links, sprintf('<a href="%s/release-%s/vep/%s_vep_%s_%s.tar.gz" class="nodeco _ht" title="Download (via FTP) all <em>%s</em> variants in VEP format">VEP</a>', $species_defs->ENSEMBL_FTP_URL, $ensembl_version, lc $species, $ensembl_version, $species_defs->ASSEMBLY_NAME, $display_name));
      my $links = join(" - ", @links);
      $html .= qq[<p><img src="${img_url}24/download.png" alt="" class="homepage-link" />Download all variants - $links</p>];
    }
  }
  else {
    $html .= '<h2>Variation</h2><p>This species currently has no variation database. However you can process your own variants using the Variant Effect Predictor:</p>';
  }

  my $new_vep = $species_defs->ENSEMBL_VEP_ENABLED;
  $html .= sprintf(
    qq(<p><a href="%s" class="%snodeco">$self->{'icon'}Variant Effect Predictor<img src="%svep_logo_sm.png" style="vertical-align:top;margin-left:12px" /></a></p>),
    $hub->url({'__clear' => 1, $new_vep ? qw(type Tools action VEP) : qw(type UserData action UploadVariations)}),
    $new_vep ? '' : 'modal_link ',
    $self->img_url
  );

  return $html;
}

1;

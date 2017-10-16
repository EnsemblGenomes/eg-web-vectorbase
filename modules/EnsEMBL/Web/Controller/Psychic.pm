package EnsEMBL::Web::Controller::Psychic;
use strict;
use warnings;

use URI::Escape qw(uri_escape);

sub psychic {
  my $self          = shift;
  my $hub           = $self->hub;
  my $species_defs  = $self->species_defs;
  my $site_type     = lc $species_defs->ENSEMBL_SITETYPE;
  my $script        = 'Search/Results';
  my %sp_hash       = %{$species_defs->multi_val('ENSEMBL_SPECIES_URL_MAP')||{}};
  my $dest_site     = $hub->param('site') || $site_type;
  my $index         = $hub->param('idx')  || undef;
  my $query         = $hub->param('q');
  my $sp_param      = $hub->param('species');
  my $species       = $sp_param || $hub->species;
     $species       = '' if $species eq 'Multi';
  my ($url, $site);

  if ($species eq 'all' && $dest_site eq 'ensembl') {
    $dest_site = 'ensembl_all';
    $species   = $species_defs->ENSEMBL_PRIMARY_SPECIES;
  }

  $query =~ s/^\s+//g;
  $query =~ s/\s+$//g;
  $query =~ s/\s+/ /g;

  $species = undef if $dest_site =~ /_all/;

  return $self->redirect("http://www.ebi.ac.uk/ebisearch/search.ebi?db=allebi&query=$query")                          if $dest_site eq 'ebi';
  return $self->redirect("http://www.sanger.ac.uk/search?db=allsanger&t=$query")                                      if $dest_site eq 'sanger';
  return $self->redirect("http://www.ensemblgenomes.org/search?site=ensembl&q=$query&site=&x=0&y=0&genomic_unit=all") if $dest_site eq 'ensembl_genomes';

## VB 
  my $vb_url = '/search/site/' . uri_escape(uri_escape($query));
  if ($species) {
    my $sp = $species_defs->get_config($species, 'SPECIES_SCIENTIFIC_NAME');
    $vb_url .= '?species_category=' . uri_escape(qq{"$sp"});
  }
## /VB

  if ($dest_site =~ /vega/) {
    if ($site_type eq 'vega') {
      $url = "/Multi/Search/Results?species=all&idx=All&q=$query";
    } else {
      $url  = "/Multi/Search/Results?species=all&idx=All&q=$query";
      $site = 'http://vega.sanger.ac.uk';
    }
  } elsif ($site_type eq 'vega') {
    $url  = "/Multi/Search/Results?species=all&idx=All&q=$query";
    $site = 'http://www.ensembl.org'; 
  } else {
## VB   
    $url = $vb_url;
## /VB
  }

  my $flag = 0;
  my $index_t;

  #if there is a species at the beginning of the query term then make a note in case we trying to jump to another location
  my ($query_species, $query_without_species);
  foreach my $sp (sort keys %sp_hash) {
    if ( $query =~ /^$sp /) {
      ($query_without_species = $query) =~ s/$sp//;
      $query_without_species =~ s/^ //;
      $query_species = $sp;
    }
  }

  my $species_path = $species_defs->species_path($species) || "/$species";

  ## If we have a species and a location can we jump directly to that page ?
  if ($species || $query_species ) {

    if ($query =~ /^rs\d+$/) {

      return $self->redirect($site.$hub->url({
        'species'   => $species || $query_species,
        'type'      => 'Variation',
        'action'    => 'Explore',
        'v'         => $query
      }));
    }

    my $real_chrs = $hub->species_defs->ENSEMBL_CHROMOSOMES;
    my $jump_query = $query;
    if ($query_species) {
      $jump_query = $query_without_species;
      $species_path = $species_defs->species_path($query_species);
    }

    if ($jump_query =~ s/^(chromosome)//i || $jump_query =~ s/^(chr)//i) {
      $jump_query =~ s/^ //;
      if (grep { $jump_query eq $_ } @$real_chrs) {
        $flag = $1;
        $index_t = 'Chromosome';
      }
    }
# VB - there are scaffolds named like ScaffoldXX - this code breaks those   
#    elsif ($jump_query =~ /^(contig|clone|supercontig|scaffold|region)/i) {
#      $jump_query =~ s/^(contig|clone|supercontig|scaffold|region)[\s_]*//i;
#      $index_t = 'Sequence';
#      $flag = $1;
#    }
# /VB

    ## match any of the following:
    if ($jump_query =~ /^\s*([-\.\w]+)[:]/i ) {
    #using core api to return location value (see perl documentation for core to see the available combination)
      my $slice_adaptor = $hub->get_adaptor('get_SliceAdaptor');
      my ($seq_region_name, $start, $end, $strand) = $slice_adaptor->parse_location_to_values($jump_query);

      $seq_region_name =~ s/chr//;
      $seq_region_name =~ s/ //g;
      $start = $self->evaluate_bp($start);
      $end   = $self->evaluate_bp($end);
      ($end, $start) = ($start, $end) if $end < $start;

      my $script = 'Location/View';
      $script    = 'Location/Overview' if $end - $start > 1000000;


      if ($index_t eq 'Chromosome') {
        $url  = "$species_path/Location/Chromosome?r=$seq_region_name";
        $flag = 1;
      } else {
        $url  = $self->escaped_url("$species_path/$script?r=%s", $seq_region_name . ($start && $end ? ":$start-$end" : ''));
        $flag = 1;
      }
    }
    else {
      if ($index_t eq 'Chromosome') {
        $jump_query =~ s/ //g;
        $url  = "$species_path/Location/Chromosome?r=$jump_query";
        $flag = 1;
      } elsif ($index_t eq 'Sequence') {
        $jump_query =~ s/ //g;
        $url  = "$species_path/Location/View?region=$jump_query";
        $flag = 1;
      }
    }

    ## other pairs of identifiers
    if ($jump_query =~ /\.\./ && !$flag) {
      ## str.string..str.string
      ## str.string-str.string
      $jump_query =~ /([\w|\.]*\w)(\.\.)(\w[\w|\.]*)/;
      $url   = $self->escaped_url("$species_path/jump_to_contig?type1=all;type2=all;anchor1=%s;anchor2=%s", $1, $3);
      $flag = 1;
    }
  }

  if (!$flag) {
## VB
      $url = $vb_url;    # everything else!
## /VB
  }

## VB
  $site = $species_defs->VECTORBASE_SEARCH_SITE if ($url eq $vb_url);
## /VB

  warn "SITE: $site, URL: $url";

  $self->redirect($site . $url);
}
1;

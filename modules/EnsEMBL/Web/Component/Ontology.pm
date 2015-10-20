=head1 LICENSE

Copyright [2009-2014] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package EnsEMBL::Web::Component::Ontology;

use strict;

use EnsEMBL::Web::Constants;
use EnsEMBL::Web::Tools::OntologyVisualisation;

sub ontology_chart {
  my ($self, $chart, $oname, $root) = @_;

  my $hub          = $self->hub;
  my $object       = $self->object;
  my $species_defs = $hub->species_defs;
  my $oid          = $hub->param('oid');
  my $go           = $hub->param('go');

  my %clusters = $species_defs->multiX('ONTOLOGIES');

  my $ontology_term_adaptor = $hub->get_databases('go')->{'go'}->get_GOTermAdaptor;

  my $ontovis = EnsEMBL::Web::Document::Image::Ontology->new($hub, undef, {'_ontology_term_adaptor' => $ontology_term_adaptor},);

  my $oMap = EnsEMBL::Web::Constants::ONTOLOGY_SETTINGS;
  my @hss = $oMap->{$oname} ? @{$oMap->{$oname}->{subsets} || []} : ();

  $ontovis->highlighted_subsets(@hss);

  my $subsets = $species_defs->get_config($object->species, 'ONTOLOGY_SUBSETS');
  my $hss = {};
  foreach my $ss (@{$subsets || []}) {
    $hss->{$ss}->{color} = $species_defs->colour('goimage', $ss) || 'grey';
    $hss->{$ss}->{label} = $species_defs->colour('goimage', $ss, 'text') || $ss;
  }

  $ontovis->highlight_subsets($hss);

  my $cmap = {
    'background'    => $species_defs->colour('goimage', 'image_background'),
    'border'        => $species_defs->colour('goimage', 'node_all_border'),
    'selected_node' => $species_defs->colour('goimage', 'node_select_background'),
  };

  foreach my $rel (@{$clusters{$oid}->{relations} || []}) {
    $cmap->{relations}->{$rel} = $species_defs->colour('goimage', $rel) || 'black';
  }

  $ontovis->colours($cmap);

  my $extlinks = $oMap->{$oname} ? $oMap->{$oname}->{extlinks} : {};

  my $bm_filter = $oMap->{$oname} ? $oMap->{$oname}->{biomart_filter} : '';
  if ($bm_filter && $species_defs->GENOMIC_UNIT && $species_defs->GENOMIC_UNIT !~ /bacteria|parasite/) {
## VB - VB-3155      
    my $vschema = sprintf qq{%s_mart_%s}, 'vb', $SiteDefs::SITE_RELEASE_VERSION;
##    
    my (@species) = split /_/, $object->species;
    my $attr_prefix = lc(substr($species[0], 0, 1) . $species[1] . "_eg_gene");

    if (my $bds = $species_defs->get_config($self->object->species, 'BIOMART_DATASET')) {
      $attr_prefix = "${bds}_gene";
    }

    my $biomart_link = sprintf qq{/biomart/martview?VIRTUALSCHEMANAME=%s&ATTRIBUTES=%s.default.feature_page.ensembl_gene_id|%s.default.feature_page.ensembl_transcript_id&FILTERS=%s.default.filters.%s.\\"###ID###\\"&VISIBLEPANEL=resultspanel}, $vschema, $attr_prefix, $attr_prefix, $attr_prefix, $bm_filter;
    $extlinks->{'Search BioMart'} = $biomart_link;
    $extlinks->{'Search BioMart'} = $biomart_link;
  }

  $ontovis->node_links($extlinks);

  my $html = $ontovis->render($chart, $root, $go, $self->image_width);
  return $html;
}

1;

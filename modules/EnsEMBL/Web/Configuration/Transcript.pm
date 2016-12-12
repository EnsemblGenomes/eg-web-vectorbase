package EnsEMBL::Web::Configuration::Transcript;

use strict;

sub modify_tree {
  my $self = shift;
  my $hub = $self->hub;
  my $object = $self->object;
  my $species_defs = $hub->species_defs;
  my $protein_variations = $self->get_node('ProtVariations');  
  
## VB
  $self->delete_node('S4_PROTEIN_STRUCTURE');  
##

# EG:ENSEMBL-2785 add this new URL so that the Transcript info appears at the top of the page for the Karyotype display with Locations tables
  my $sim_node = $self->get_node('Similarity');
  $sim_node->append($self->create_subnode('Similarity/Locations', '',
    [qw(
       genome  EnsEMBL::Web::Component::Location::Genome
    ) ],
    {  'availability' => 'transcript', 'no_menu_entry' => 1 }
  ));
# EG:ENSEMBL-2785 end
  
}


1;


package EnsEMBL::Web::Configuration::Gene;
use strict;
use warnings;

use previous qw(modify_tree);

sub modify_tree {
  my $self = shift;

  $self->PREV::modify_tree(@_);

  my $hub = $self->hub;
  my $species = $hub->species;
  my $species_defs = $hub->species_defs;
  my $object = $self->object;

  # delete unwanted nodes
  $self->delete_node($_) for (qw(Alleles SecondaryStructure Gene_families ExpressionAtlas PanCompara Regulation));

  if ($object) {
    # add expression node
    my $expression_node = $self->create_node('GeneExpressionReporters', 'Expression report', [], 
      { 
        'availability' => 'gene has_expression', 
        'url' => $SiteDefs::VECTORBASE_EXPRESSION_BROWSER . "/gene/" . $object->param('g'), 
        'raw' => 1 
      }
    );

    $self->get_node('Variation')->after($expression_node);
  }
}

1;

package EnsEMBL::Web::Configuration::Location;
use strict;
use warnings;

use previous qw(modify_tree);

sub modify_tree {
  my $self  = shift;
  my $species_defs = $self->hub->species_defs;

  $self->PREV::modify_tree;

  $self->delete_node('LD');
}

1;

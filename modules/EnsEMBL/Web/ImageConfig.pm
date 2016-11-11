package EnsEMBL::Web::ImageConfig;

use strict;
use previous qw(menus);

sub menus {
  my $self  = shift;
  my $menus = $self->PREV::menus(@_);
  my $add   = {
   rnaseq_align => 'RNAseq alignments',
  };
  return { %$menus, %$add };
}

1;

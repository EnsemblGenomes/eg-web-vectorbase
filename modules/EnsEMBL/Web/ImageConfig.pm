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

sub add_oligo_probes {
  my ($self, $key, $hashref) = @_;
  my $menu = $self->get_node('oligo');

  return unless $menu;

  my $data = $hashref->{'oligo_feature'}{'arrays'};
## VB
  #my $description = $hashref->{'oligo_feature'}{'analyses'}{'AlignAffy'}{'desc'};  # Different loop - no analyses - base on probeset query results
##
  foreach my $key_2 (sort keys %$data) {
    my $key_3 = $key_2;
    $key_2    =~ s/:/__/;

## VB
    my $description = $hashref->{'oligo_feature'}{'descriptions'}{$key_3};
##

    $menu->append($self->create_track("oligo_${key}_" . uc $key_2, $key_3, {
      glyphset    => '_oligo',
      db          => $key,
      sub_type    => 'oligo',
      array       => $key_2,
      object_type => 'ProbeFeature',
      colourset   => 'feature',
      description => $description,
      caption     => $key_3,
      strand      => 'b',
      display     => 'off',
      renderers   => $self->{'alignment_renderers'}
    }));
  }
}


1;

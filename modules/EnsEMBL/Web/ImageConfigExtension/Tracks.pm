=head1 LICENSE

Copyright [1999-2016] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::ImageConfigExtension::Tracks;

### An Extension to EnsEMBL::Web::ImageConfig
### Methods to load default tracks

package EnsEMBL::Web::ImageConfig;

use strict;

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

    $menu->append_child($self->create_track_node("oligo_${key}_" . uc $key_2, $key_3, {
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
      renderers   => $self->_alignment_renderers
    }));
  }
}

1;

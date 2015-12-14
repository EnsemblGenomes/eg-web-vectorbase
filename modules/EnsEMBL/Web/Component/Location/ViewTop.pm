=head1 LICENSE

Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Component::Location::ViewTop;

use strict;
use previous qw(content);

## VB - hack to make web apollo url avaialble to zmenu and genoverse javascript   
sub content {
  my $self    = shift;
  my $content = $self->PREV::content;
  return if !$content;
  
  my $species_defs = $self->hub->species_defs;

  if (my $sp = $species_defs->WEBAPOLLO_SPECIES) {
    my $url = $species_defs->WEBAPOLLO_URL_TEMPLATE =~ s/###ID###/$sp/r;
    $content .= qq(<input type="hidden" id="webapollo-url" value="$url" />);
  }

  return $content;
}
##

1;

=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Document::Element::BodyJavascript;

use strict;
use warnings;

use previous qw(init);

## VB add JS for VB search autocomplete
sub init {
  my $self = shift;
  $self->PREV::init(@_);
  $self->add_script('https://www.vectorbase.org/sites/all/modules/custom/vbsearch/modules/vbsearch_autocomplete/vbsearch_autocompletev2.js');
}
##

1;

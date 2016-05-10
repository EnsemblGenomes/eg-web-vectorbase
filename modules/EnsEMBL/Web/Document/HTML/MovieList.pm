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

package EnsEMBL::Web::Document::HTML::MovieList;

### This module outputs a selection of news headlines for the home page, 
### based on the user's settings or a default list

use strict;
use previous qw(render);

## VB-4939 hack to fix movie links
sub render {
  my $self   = shift;
  my $html   = $self->PREV::render(@_);
  my $prefix = 'http://www.ensembl.org';
  
  $html =~ s|href="/Multi/Help/Movie|href="$prefix/Multi/Help/Movie|g;
  
  return $html; 
}

1;

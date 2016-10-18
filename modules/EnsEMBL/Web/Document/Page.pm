=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Document::Page;

use strict;
use previous qw(ajax_redirect);

## VB-5607 add sanitisation to prevent CRLF injection 
## (for some reason this only manifested on VB servers, hence this hasn't been pushed to Ensembl)
sub ajax_redirect {
  my $self      = shift;
  my $url       = $_[0];  
  my $back      = $self->{'input'}->param('wizard_back');
  my @backtrack = map $url =~ /_backtrack=$_\b/ ? () : $_, $self->{'input'}->param('_backtrack');

  for ($url, $back, @backtrack) {
    if (/[\n\r]/) { 
      warn "Request declined; URL looks unsafe";
      $self->renderer->{'r'}->status(Apache2::Const::FORBIDDEN);
      return;
    }
  }

  return $self->PREV::ajax_redirect(@_);
}

1;

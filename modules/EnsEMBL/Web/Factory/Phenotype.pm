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

package EnsEMBL::Web::Factory::Phenotype;

use strict;
use warnings;
no warnings 'uninitialized';

use HTML::Entities qw(encode_entities);

sub _help {
  my ($self, $string) = @_;

  my $help_text = $string ? sprintf '<p>%s</p>', encode_entities($string) : '';
  my $url       = $self->hub->url({ __clear => 1, action => 'All'});

  $help_text .= sprintf('
    <p>
      This view requires a phenotype identifier.
    </p>
    <p>
      Please make a selection from the <a href="%s">List of phenotypes</a>
    </p>',
    encode_entities($url),
  );

  return $help_text;
}


1;

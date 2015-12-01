=head1 LICENSE

Copyright [2009-2014] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Component::Shared;

use strict;
use previous qw(transcript_table);

sub transcript_table {
  my $self = shift;
  my $html = $self->PREV::transcript_table(@_);

## VB-4096 add indian strain links
    $html =~ s/(Projected from Indian strain )\((:?[^\(\\s)]+)\)/$1 (<a href="\/Anopheles_stephensiI\/Gene\/Summary\?g=$2">$2<\/a>)/m;
    $html =~ s/(Projected from SDA\-500 strain )\((:?[^\(\\s)]+)\)/$1 (<a href="\/Anopheles_stephensi\/Gene\/Summary\?g=$2">$2<\/a>)/m;
##

  return $html;
}

1;

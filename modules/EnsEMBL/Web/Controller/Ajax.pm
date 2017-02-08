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

package EnsEMBL::Web::Controller::Ajax;

use strict;
use warnings;

use HTML::Entities qw(decode_entities);
use JSON;

sub ajax_table_export {
  ## /Ajax/table_export endpoint
  ## Converts an HTML table into CSV by stripping out HTML tags
  my $self    = shift;
  my $hub     = $self->hub;
  my $r       = $hub->r;
  my $data    = from_json($hub->param('data'));
  my $clean   = sub {
    my ($str,$opts) = @_;
    # Remove summaries, ugh.
    $str =~ s!<span class="toggle_summary[^"]*">.*?</span>!!g;
    # Remove hidden spans
    $str =~ s!<span class="hidden">[^\<]*</span>!!g;
    # split multiline columns
    for (2..($opts->{'split_newline'} || 0)) {
      unless($str =~ s/<br.*?>/\0/) {
        $str =~ s/$/\0/;
      }
    }
    #
    $str =~ s/<br.*?>/ /g;
    $str =~ s/\xC2\xAD//g;     # Layout codepoint (shy hyphen)
    $str =~ s/\xE2\x80\x8B//g; # Layout codepoint (zero-width space)
    $str =~ s/\R//g;
    $str =~ s/^\s+//;
    $str =~ s/\s+$//g;
    $str = $self->strip_HTML(decode_entities($str));
## VB - temporary fix implemenmts https://github.com/Ensembl/ensembl-webcode/pull/520/
##      remove for E88 
    $str =~ s/\xA0/ /g;  
##    
    $str =~ s/"/""/g;
    $str =~ s/\0/","/g;
    return $str;
  };

  $r->content_type('application/octet-string');
  $r->headers_out->add('Content-Disposition' => sprintf 'attachment; filename=%s.csv', $hub->param('filename'));

  my $options = from_json($hub->param('expopts')) || ();
  foreach my $row (@$data) {
    my @row_out;
    my @row_opts = @$options;
    foreach my $col (@$row) {
      my $opt = shift @row_opts;
      push @row_out,sprintf('"%s"',$clean->($col,$opt || {}));
    }
    print join(',',@row_out)."\n";
  }
}


1;

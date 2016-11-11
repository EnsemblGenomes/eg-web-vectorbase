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

package EnsEMBL::Web::ZMenu::UserData;

use strict;

use base qw(EnsEMBL::Web::ZMenu);

our %strand_text = (
                    '1'   => 'Forward',
                    '-1'  => 'Reverse',
                    '0'   => 'None',
);

sub feature_content {
  my ($self, $features, $caption) = @_;

  my $default_caption = 'Feature';
  $default_caption   .= 's' if scalar @$features > 1;

  foreach (@$features) {
    my $id = $_->{'label'};

    unless ($caption) {
      $caption = $_->{'track_name'} || $default_caption;
      $caption .= ': '.$id if scalar(@$features) == 1 && $id; 
    }

    $self->add_entry({'type' => 'Location', 
                      'label' => sprintf('%s:%s-%s', 
                                            $_->{'seq_region'}, 
                                            $_->{'start'}, 
                                            $_->{'end'})
                      });

    if (defined($_->{'strand'})) {
      $self->add_entry({'type' => 'Strand', 'label' => $strand_text{$_->{'strand'}}});
    }

    if (defined($_->{'score'})) {
      $self->add_entry({'type' => 'Score', 'label' => $_->{'score'}});
    }

    if ($_->{'extra'}) {
      foreach my $extra (@{$_->{'extra'}||[]}) {
        next unless $extra->{'name'};
        if ($extra->{'value'} =~ /<a href/) {
          $self->add_entry({'type' => $extra->{'name'}, 'label_html' => $extra->{'value'}});
        }
## VB-5743 - add mark-up for web links 
##           remove for E87+ if this pull request merged https://github.com/Ensembl/ensembl-webcode/pull/504
        elsif ($extra->{'name'} =~ /^url$/i) {
          $self->add_entry({'type' => 'Link', 'label_html' => sprintf('<a href="%s">%s</a>', $extra->{'value'}, $extra->{'value'})});
        }
##        
        else {
          $self->add_entry({'type' => $extra->{'name'}, 'label' => $extra->{'value'}});
        }
      }
    }

    my $url = $_->{'url'};
    if ($url) {
      if ($id) {
        $url =~ s/\$\$/$id/e;
      }
      $self->add_entry({'type' => 'Link', 'label_html' => sprintf('<a href="%s">%s</a>', $url, $id)});
    }
  }

  $self->caption($caption);
}

1;

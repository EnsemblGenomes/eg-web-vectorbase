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

package EnsEMBL::Web::Controller::Page;

use strict;

use URI::Escape qw(uri_unescape);

## VB - bolt on configure-by-POST functionality for the external Sample Picker app. 

use previous qw(update_configuration_from_url);

sub update_configuration_from_url {
  my $self = shift;
  my $updated = $self->PREV::update_configuration_from_url(@_);
  if (!$updated) {
    $updated = $self->update_configuration_from_post;
  }
  return $updated;
}

sub update_configuration_from_post {
  my $self       = shift;
  my $r          = $self->r;
  return unless $r->method eq 'POST';

  my $input      = $self->input;
  my $hub        = $self->hub;
  my @components = @{$self->configuration->get_configurable_components};

  my $updated;
  for (@components) {
    my $view_config = $hub->get_viewconfig(@{$_});
    $view_config->reset;
    $updated = $view_config->update_from_input || $updated;
  }
  
  if ($updated) {
    $hub->session->store;
    $input->param('time', time); # Add time to cache-bust the browser
    $input->redirect(join '?', $r->uri, uri_unescape($input->query_string)); # If something has changed then we redirect to the new page  
    return 1;
  }
}

##

1;

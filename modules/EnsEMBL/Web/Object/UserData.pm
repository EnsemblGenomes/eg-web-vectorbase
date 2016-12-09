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

package EnsEMBL::Web::Object::UserData;


## VB-5809 - back-porting TH fixes that went into E87 - can remove these for January release

sub thr_fetch {
  my ($self, $endpoint) = @_;

  ## REST call
  my $registry = $self->hub->species_defs->TRACKHUB_REGISTRY_URL;
  my $rest = EnsEMBL::Web::REST->new($self->hub, $registry);
  return unless $rest;

  return $rest->fetch($endpoint);
}

sub thr_search {
  my ($self, $url_params) = @_;
  my $hub = $self->hub;

  ## REST call
  my $registry = $hub->species_defs->TRACKHUB_REGISTRY_URL;
  my $rest = EnsEMBL::Web::REST->new($hub, $registry);
  return unless $rest;

  my ($result, $error);
  my $endpoint = 'api/search';
  my $post_content = {'query' => $hub->param('query')};

  ## We have to rename these params within the webcode as they conflict with ours
  $post_content->{'type'}     = $hub->param('data_type');
  $post_content->{'species'}  = $hub->param('thr_species');

  ## Search by either assembly or accession, depending on config
  my $key = $hub->param('assembly_key');
  $key = 'assembly' if $key eq 'name';
  $post_content->{$key} = $hub->param('assembly_id');

  my $args = {'method' => 'post', 'content' => $post_content};
  $args->{'url_params'} = $url_params if $url_params;

  return $rest->fetch($endpoint, $args);
}

sub thr_ok_species {
### Check a roster of species against the ones in the THR
  my ($self, $thr_species, $current_species) = @_;
  my $hub = $self->hub;
  my $ok_species;

  my $sci_name        = $hub->species_defs->get_config($current_species, 'SPECIES_SCIENTIFIC_NAME');
  my $assembly_param  = $hub->species_defs->get_config($current_species, 'THR_ASSEMBLY_PARAM')
                            || 'ASSEMBLY_ACCESSION';
  my $assembly        = $hub->species_defs->get_config($current_species, $assembly_param);
  my $key             = $assembly_param eq 'ASSEMBLY_ACCESSION' ? 'accession' : 'name';

  if ($thr_species->{$sci_name}) {
    ## Check that we have the right assembly
    my $found = 0;
    ($found, $key) = $self->_find_assembly($thr_species->{$sci_name}, $assembly_param, $key, $assembly);
    if ($found) {
      $ok_species = {'thr_name' => $sci_name, 'assembly_key' => $key, 'assembly_id' => $assembly};
    }
  }
  else {
    ## No exact match, so try everything else
    while (my ($sp_name, $info) = each (%$thr_species)) {
      my $found = 0;
      ($found, $key) = $self->_find_assembly($info, $assembly_param, $key, $assembly);;
      if ($found) {
        $ok_species = {'thr_name' => $sp_name, 'assembly_key' => $key, 'assembly_id' => $assembly};
        last;
      }
    }
  }
  return $ok_species;
}

sub _find_assembly {
  my ($self, $info, $assembly_param, $key, $assembly) = @_;
  my $found = 0;

  if ($assembly_param eq 'ASSEMBLY_ACCESSION') {
    foreach (@$info) {
      if ($_->{'accession'} eq $assembly) {
        $found = 1;
        last;
      }
    }
  }
  else {
    ## Check name and synonyms
    foreach (@$info) {
      if ($_->{'name'} eq $assembly) {
        $found = 1;
      }
      else {
        foreach (@{$_->{'synonyms'}||[]}) {
          if ($_ eq $assembly) {
            $found = 1;
            $key = 'synonyms';
            last;
          }
        }
      }
      last if $found;
    }
  }
  return ($found, $key);
}

## /VB-5809

1;

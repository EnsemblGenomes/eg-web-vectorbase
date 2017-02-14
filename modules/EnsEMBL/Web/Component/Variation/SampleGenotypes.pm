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

package EnsEMBL::Web::Component::Variation::SampleGenotypes;

use strict;

sub content {
  my $self         = shift;
  my $object       = $self->object;
  my $hub          = $self->hub;
  my $selected_pop = $hub->param('pop');
  
  
  my $pop_obj  = $selected_pop ? $self->hub->get_adaptor('get_PopulationAdaptor', 'variation')->fetch_by_dbID($selected_pop) : undef;
  my %sample_data = %{$object->sample_table($pop_obj)};

  return sprintf '<h3>No sample genotypes for this SNP%s %s</h3>', $selected_pop ? ' in population' : '', $pop_obj->name unless %sample_data;

  my (%rows, %pop_names);
  my $flag_children = 0;
  my $allele_string = $self->object->alleles;
  my $al_colours = $self->object->get_allele_genotype_colours;

  my %group_name;
  my %priority_data;
  my %other_pop_data;
  my %other_sample_data;

## VB
  my @names = map {$_->{'Name'}} values %sample_data;
  
  my $samples = $hub->database('variation')->dbc->db_handle->selectall_arrayref(
    "SELECT i.name, iss.name FROM individual i, individual_synonym iss, source s
     WHERE i.individual_id = iss.individual_id
     AND s.source_id = iss.source_id
     AND s.name = 'VBPopBio'
     AND i.name IN ('" . join("', '", @names) . "')"
  );

  my %sample_name = map { $_->[0] => $_->[1] } @$samples;
##
  foreach my $sample_id (sort { $sample_data{$a}{'Name'} cmp $sample_data{$b}{'Name'} } keys %sample_data) {
    my $data     = $sample_data{$sample_id};
    my $genotype = $data->{'Genotypes'};
    
    next if $genotype eq '(indeterminate)';
    
    my $father      = $self->format_parent($data->{'Father'});
    my $mother      = $self->format_parent($data->{'Mother'});
    my $description = $data->{'Description'} || '-';
    my %populations;
    
    my $other_sample = 0;
    
    foreach my $pop(@{$data->{'Population'}}) {
      my $pop_id = $pop->{'ID'};
      next unless ($pop_id);
      
      $pop->{'Label'} = $pop->{'Name'};

      if ($pop->{'Size'} == 1) {
        $other_sample = 1;
        $other_sample_data{$pop_id} = 1;
      }
      else {
        $populations{$pop_id} = 1;
        $pop_names{$pop_id} = $pop->{'Name'};
        
        if ($pop->{'Label'} =~ /(1000genomes|hapmap)/i) {
          my @composed_name = split(':', $pop->{'Label'});
          $pop->{'Label'} = $composed_name[$#composed_name];
        }

        my $priority_level = $pop->{'Priority'};
        if ($priority_level) {
          $group_name{$priority_level} = $pop->{'Group'} unless defined $group_name{$priority_level};
          $priority_data{$priority_level}{$pop_id} = {'name' => $pop->{'Name'}, 'label' => $pop->{'Label'}, 'link' => $pop->{'Link'}};
        }
        else {
          $other_pop_data{$pop_id} = {'name' => $pop->{'Name'}, 'label' => $pop->{'Label'}, 'link' => $pop->{'Link'}};
        }
      }
    }
    
    # Colour the genotype
    foreach my $al (keys(%$al_colours)) {
      $genotype =~ s/$al/$al_colours->{$al}/g;
    } 
    
    my $sample_label = $data->{'Name'};
    if ($sample_label =~ /(1000\s*genomes|hapmap)/i) {
      my @composed_name = split(':', $sample_label);
      $sample_label = $composed_name[$#composed_name];
    }

    my $row = {
## VB      
      Sample  => sprintf("<small id=\"$data->{'Name'}\"><a href=\"/popbio/sample/?id=%s\">$sample_label</a> (%s)</small>", $sample_name{$data->{'Name'}}, substr($data->{'Gender'}, 0, 1)),
##
      Genotype    => "<small>$genotype</small>",
      Population  => "<small>".join(", ", sort keys %{{map {$_->{Label} => undef} @{$data->{Population}}}})."</small>",
      Father      => "<small>".($father eq '-' ? $father : "<a href=\"#$father\">$father</a>")."</small>",
      Mother      => "<small>".($mother eq '-' ? $mother : "<a href=\"#$mother\">$mother</a>")."</small>",
      Children    => '-'
    };
    
    my @children = map { sprintf "<small><a href=\"#$_\">$_</a> (%s)</small>", substr($data->{'Children'}{$_}[0], 0, 1) } keys %{$data->{'Children'}};
    
    if (@children) {
      $row->{'Children'} = join ', ', @children;
      $flag_children = 1;
    }
    
    if ($other_sample == 1 && scalar(keys %populations) == 0) {  
      push @{$rows{'other_sample'}}, $row;
      ## need this to display if there is only one genotype for a sequenced sample
      $pop_names{"other_sample"} = "single samples";
    }
    else {
      push @{$rows{$_}}, $row foreach keys %populations;
    }
  }
  
  my $columns = $self->get_table_headings;
  
  push @$columns, { key => 'Children', title => 'Children<br /><small>(Male/Female)</small>', sort => 'none', help => 'Children names and genders' } if $flag_children;
    
  
  if ($selected_pop || scalar keys %rows == 1) {
    $selected_pop ||= (keys %rows)[0]; # there is only one entry in %rows

    my $pop_name = $pop_names{$selected_pop};
    my $project_url  = $self->pop_url($pop_name,$pop_name);
    my $pop_url = ($project_url) ? sprintf('<div style="clear:both"></div><p><a href="%s" rel="external">More information about the <b>%s</b> population</a></p>', $project_url, $pop_name) : ''; 

    return $self->toggleable_table(
      "Genotypes for $pop_names{$selected_pop}", $selected_pop, 
      $self->new_table($columns, $rows{$selected_pop}, { data_table => 1, sorting => [ 'Sample asc' ] }),
      1,
      qq{<span style="float:right"><a href="#}.$self->{'id'}.qq{_top">[back to top]</a></span><br />}
    ).$pop_url;
  }
  
  return $self->summary_tables(\%rows, \%priority_data, \%other_pop_data, \%other_sample_data, \%group_name, $columns);
}

1;

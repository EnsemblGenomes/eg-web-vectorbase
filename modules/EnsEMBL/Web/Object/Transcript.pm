package EnsEMBL::Web::Object::Transcript;

use strict;

sub availability {
  my $self = shift;
  
  if (!$self->{'_availability'}) {
    my $availability = $self->_availability;
    my $obj = $self->Obj;
    
    if ($obj->isa('EnsEMBL::Web::Fake')) {
      $availability->{$self->feature_type} = 1;
    } elsif ($obj->isa('Bio::EnsEMBL::ArchiveStableId')) { 
      $availability->{'history'} = 1;
      my $trans_id = $self->param('p') || $self->param('protein'); 
      my $trans = scalar @{$obj->get_all_translation_archive_ids};
      $availability->{'history_protein'} = 1 if $trans_id || $trans >= 1;
    } elsif( $obj->isa('Bio::EnsEMBL::PredictionTranscript') ) {
      $availability->{'either'} = 1;
      $availability->{'translation'} = 1;
    } else {
      my $counts = $self->counts;
      my $rows   = $self->table_info($self->get_db, 'stable_id_event')->{'rows'};
      
## VB
      my $core_db       = $self->database('core');
      my $stable_id     = $self->Obj->display_id;
      my $history_count = $core_db->dbc->db_handle->selectrow_array('SELECT count(*) FROM stable_id_event WHERE old_stable_id = ? OR new_stable_id = ?', undef, $stable_id, $stable_id);
      $availability->{history}  = !!$history_count;
      $availability->{'history_protein'} = !!$history_count;
##
      $availability->{'core'}            = $self->get_db eq 'core';
      $availability->{'either'}          = 1;
      $availability->{'transcript'}      = 1;
      $availability->{'not_pred'}        = 1;
      $availability->{'domain'}          = 1;
      $availability->{'translation'}     = !!$obj->translation;
      $availability->{'strains'}         = !!$self->species_defs->databases->{'DATABASE_VARIATION'}->{'#STRAINS'} if $self->species_defs->databases->{'DATABASE_VARIATION'};
      $availability->{'history_protein'} = 0 unless $self->translation_object;
      $availability->{'has_variations'}  = $counts->{'prot_variations'};
      $availability->{'has_domains'}     = $counts->{'prot_domains'};
      $availability->{"has_$_"}          = $counts->{$_} for qw(exons evidence similarity_matches oligos go);
    }
  
    $self->{'_availability'} = $availability;
  }
  
  return $self->{'_availability'};
}

sub sort_oligo_data {
  my ($self, $probe_data) = @_; 
  my $hub        = $self->hub;

  foreach my $array (sort keys %$probe_data) {
    my $text;
    my $p_type = 'pset';
    my %data   = %{$probe_data->{$array}};
    foreach my $probe_name (sort keys %data) {
      my ($p_type, $probe_text) = @{$data{$probe_name}};
      
      my $url = $hub->url({
        'type'   => 'Location',
        'action' => 'Genome',
        'id'     => $probe_name,
        'ftype'  => 'ProbeFeature',
        'fdb'    => 'funcgen',
        'ptype'  => $p_type, 
      });
      
      $text .= '<p>';
## VB 
      if ($array =~ /^AFFY/ and $p_type ne 'pset') { # only show link for AFFY probeset, not the probes
        $text .= $probe_name;
      } else {
        $text .= sprintf '<a href="%s/reporter/%s">%s</a>', $self->hub->species_defs->VECTORBASE_EXPRESSION_BROWSER, $probe_name, $probe_name;
      }
## 
      $text .= qq{ <span class="small">[$probe_text]</span>} if $probe_text;
      $text .= qq{  [<a href="$url">view all locations</a>]</p>};
    }
    
    push @{$self->__data->{'links'}{'ARRAY'}}, [ $array || $array, $text ];
  }
}

1;

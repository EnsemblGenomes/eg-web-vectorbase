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
      $availability->{"has_$_"}          = $counts->{$_} for qw(exons evidence similarity_matches oligos);
      $availability->{ref_slice}       //= $self->Obj->slice->is_reference();
    }
  
    $self->{'_availability'} = $availability;
  }
  
  return $self->{'_availability'};
}


sub get_alignment {
  my $self = shift;
  my $ext_seq  = shift || return undef;
  my $int_seq  = shift || return undef;
  $int_seq =~ s/<br \/>//g;
  my $seq_type = shift || return undef;

  # To stop box running out of memory - put an upper limit on the size of sequence
  # that alignview can handle
  if (length $int_seq > 1e6 || length $ext_seq > 1e6)  {
    $self->problem('fatal', 'Cannot align if sequence > 1 Mbase');
    return 'Sorry, cannot do the alignments if sequence is longer than 1 Mbase';
  }

  my $int_seq_file = $self->save_seq($int_seq);
  my $ext_seq_file = $self->save_seq($ext_seq);

  ####
  #We deal with having to use the reverse complement of a hit sequence by telling PFETCH to retrieve it where appropriate
  #This will deal with all situations I am aware of, but a better way of doing it could be to use EMBOSS revcomp before running matcher
  ####

  my $label_width  = '22'; # width of column for e! object label
  my $output_width = 61;   # width of alignment
  my $dnaAlignExe  = '%s/bin/matcher -asequence %s -bsequence %s -outfile %s';

##VB START
 my $pepAlignExe  = '%s/bin/psw -dymem explicit -m %s/wisecfg/blosum62.bla %s %s -n %s -w %s > %s';
##VB END

  my $out_file = time() . int(rand()*100000000) . $$;
  $out_file = $self->species_defs->ENSEMBL_TMP_TMP.'/' . $out_file . '.out';

  my $command;
  if ($seq_type eq 'DNA') {
    $command = sprintf $dnaAlignExe, $self->species_defs->ENSEMBL_EMBOSS_PATH, $int_seq_file, $ext_seq_file, $out_file;
    `$command`;

    unless (open(OUT, "<$out_file")) {
      $self->problem('fatal', "Cannot open alignment file.", $!);
    }
  } elsif ($seq_type eq 'PEP') {

##VB START
    $command = sprintf $pepAlignExe, $self->species_defs->ENSEMBL_WISE2_PATH, $self->species_defs->ENSEMBL_WISE2_PATH, $int_seq_file, $ext_seq_file,$label_width, $output_width, $out_file;
##VB END

    `$command`;

    unless (open(OUT, "<$out_file")) {
      $self->problem('fatal', "Cannot open alignment file.", $!);
    }
  } else {
    return undef;
  }

  my $alignment ;
  while (<OUT>) {
    next if $_ =~
    /\#Report_file
     |\#----.*
     |\/\/\s*
     |\#\#\#
     |^\#$
     |Rundate: #matcher
     |Commandline #matcher
     |asequence #matcher
     |bsequence #matcher
     |outfile #matcher
     |aformat #matcher
     |Align_format #matcher
     |Report_file #matcher
     /x;

    $alignment .= $_;
  }

  $alignment =~ s/\n+$//;
  unlink $out_file;
  unlink $int_seq_file;
  unlink $ext_seq_file;
  return $alignment;
}

1;

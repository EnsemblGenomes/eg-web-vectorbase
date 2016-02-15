# $Id: Gene.pm,v 1.14 2014-01-23 16:25:18 nl2 Exp $

package EnsEMBL::Web::Object::Gene;

use strict;
use previous qw(
  availability 
  counts
);

sub availability {
  my $self = shift;
  
  if (!$self->{'_availability'}) {
    if ($self->Obj->isa('Bio::EnsEMBL::Gene')) {
      my $availability = $self->PREV::availability(@_);

      my $core_db       = $self->database('core');
      my $stable_id     = $self->Obj->stable_id;
      my $history_count = $core_db->dbc->db_handle->selectrow_array('SELECT count(*) FROM stable_id_event WHERE old_stable_id = ? OR new_stable_id = ?', undef, $stable_id, $stable_id);
      $availability->{history} = !!$history_count;

      my $counts = $self->counts;
      $availability->{"has_$_"} = $counts->{$_} for qw(expression pathways);
      $availability->{'pubmed'}        = !!$counts->{pubmed};
      $self->{'_availability'} = $availability;
    }
  }
  return $self->{'_availability'};
}

sub counts {
  my $self = shift;

  return {} unless $self->Obj->isa('Bio::EnsEMBL::Gene');
  
  if (!$self->{'_counts'}) {
    my $counts = $self->PREV::counts(@_);
    $counts->{expression} = $self->count_gene_oligos;
    $counts->{pubmed}     = $self->count_pubmed;
    $counts->{pathways}   = $self->count_pathways;
  }
    
  return $self->{'_counts'};
}

## VB

sub count_pubmed {
  my $self = shift;
  my $obj = $self->Obj;
  my $type = 'core';
  return 0 unless $self->database('core');
  my $dbh = $self->database($type)->dbc;

  my $sql = qq{
    SELECT count(distinct(ox.xref_id))
    FROM object_xref ox, xref x, external_db edb
    WHERE ox.xref_id = x.xref_id
      AND x.external_db_id = edb.external_db_id
      AND edb.db_name = 'PUBMED'
      AND ox.ensembl_object_type = 'Gene'
      AND ox.ensembl_id = ?
  };

  my $sth = $dbh->prepare($sql);
  $sth->execute($self->gene->dbID);                                                                                                                                                                                                           
  
  return $sth->fetchall_arrayref->[0][0];
}

sub count_pathways {
  my $self = shift;
  my $obj = $self->Obj;
  my $type = 'core';
  return 0 unless $self->database('core');
  my $dbh = $self->database($type)->dbc;

  my $sql = qq{
    SELECT count(distinct(ox.xref_id))
    FROM object_xref ox, xref x, external_db edb
    WHERE ox.xref_id = x.xref_id
      AND x.external_db_id = edb.external_db_id
      AND edb.db_name = 'KEGG'
      AND ox.ensembl_object_type = 'Gene'
      AND ox.ensembl_id = ?
  };

  my $sth = $dbh->prepare($sql);
  $sth->execute($self->gene->dbID);                                                                                                                                                                                                           
  
  return $sth->fetchall_arrayref->[0][0];
}

sub count_gene_oligos {
    my $self = shift;
    my $obj = $self->Obj;
    my $type = 'funcgen';
    return 0 unless $self->database('funcgen');
    my $dbc = $self->database($type)->dbc;

    # OLIGOS
    # get all transcripts IDs
    my @ids = ();
    foreach my $transcript (@{$self->gene()->get_all_Transcripts}){
 
        push @ids, "'" . $transcript->display_id() . "'";

    }
    
    my $idsStr = join(",", @ids);


    my $sql = qq{
   SELECT count(distinct(ox.ensembl_id))
     FROM object_xref ox, xref x, external_db edb
    WHERE ox.xref_id = x.xref_id
      AND x.external_db_id = edb.external_db_id
      AND (ox.ensembl_object_type = 'ProbeSet'
           OR ox.ensembl_object_type = 'Probe')
      AND x.info_text = 'Transcript'
      AND x.dbprimary_acc in ($idsStr) };
      
    my $sth = $dbc->prepare($sql); 
    $sth->execute() ; #$self->Obj->stable_id);
    my $c = $sth->fetchall_arrayref->[0][0];
    return $c;
}

## /VB

1;

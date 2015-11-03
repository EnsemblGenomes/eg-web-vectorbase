# $Id: Gene.pm,v 1.14 2014-01-23 16:25:18 nl2 Exp $

package EnsEMBL::Web::Object::Gene;

sub availability {
  my $self = shift;
  my ($database_synonym) = @_;
  
  if (!$self->{'_availability'}) {
    my $availability = $self->_availability;
    my $obj = $self->Obj;
    
    if ($obj->isa('Bio::EnsEMBL::ArchiveStableId')) {
      $availability->{'history'} = 1;
    } elsif ($obj->isa('Bio::EnsEMBL::Gene')) {
      my $member      = $self->database('compara') ? $self->database('compara')->get_GeneMemberAdaptor->fetch_by_source_stable_id('ENSEMBLGENE', $obj->stable_id) : undef;
      my $pan_member  = $self->database('compara_pan_ensembl') ? $self->database('compara_pan_ensembl')->get_GeneMemberAdaptor->fetch_by_source_stable_id('ENSEMBLGENE', $obj->stable_id) : undef;
      my $counts      = $self->counts($member, $pan_member);
      my $rows        = $self->table_info($self->get_db, 'stable_id_event')->{'rows'};
      my $funcgen_res = $self->database('funcgen') ? $self->table_info('funcgen', 'feature_set')->{'rows'} ? 1 : 0 : 0;

## VB
      my $core_db       = $self->database('core');
      my $stable_id     = $self->Obj->stable_id;
      my $history_count = $core_db->dbc->db_handle->selectrow_array('SELECT count(*) FROM stable_id_event WHERE old_stable_id = ? OR new_stable_id = ?', undef, $stable_id, $stable_id);
      $availability->{history} = !!$history_count;
##
      $availability->{'gene'}                 = 1;
      $availability->{'core'}                 = $self->get_db eq 'core';
      $availability->{'has_gene_tree'}        = $member ? $member->has_GeneTree : 0;
      $availability->{'can_r2r'}              = $self->hub->species_defs->R2R_BIN;
      if ($availability->{'can_r2r'}) {
        my $tree = $availability->{'has_gene_tree'} ? $self->database('compara')->get_GeneTreeAdaptor->fetch_default_for_Member($member) : undef;
        $availability->{'has_2ndary_cons'}    = $tree && $tree->get_tagvalue('ss_cons') ? 1 : 0;
        $availability->{'has_2ndary'}         = ($availability->{'has_2ndary_cons'} || ($obj->canonical_transcript && scalar(@{$obj->canonical_transcript->get_all_Attributes('ncRNA')}))) ? 1 : 0;
      }
      $availability->{'has_gxa'}              = $self->gxa_check;

      $availability->{'alt_allele'}           = $self->table_info($self->get_db, 'alt_allele')->{'rows'};
      $availability->{'regulation'}           = !!$funcgen_res; 
      $availability->{'has_species_tree'}     = $member ? $member->has_GeneGainLossTree : 0;
      $availability->{'family'}               = !!$counts->{families};
      $availability->{'family_count'}         = $counts->{families};
      $availability->{'not_rnaseq'}           = $self->get_db eq 'rnaseq' ? 0 : 1;
## VB      
      $availability->{"has_$_"}               = $counts->{$_} for qw(expression pathways go transcripts alignments paralogs orthologs similarity_matches operons structural_variation pairwise_alignments);
##
      $availability->{'multiple_transcripts'} = $counts->{'transcripts'} > 1;
      $availability->{'not_patch'}            = $obj->stable_id =~ /^ASMPATCH/ ? 0 : 1; ## TODO - hack - may need rewriting for subsequent releases
## VB      
      $availability->{'pubmed'}        = !!$counts->{pubmed};
## /VB      
      my $phen_avail = 0;
      if ($self->database('variation')) {
        $availability->{'has_phenotypes'} = $self->get_phenotype; 
      }
      
      if ($self->database('compara_pan_ensembl')) {
        $availability->{'family_pan_ensembl'} = !!$counts->{families_pan};
        $availability->{'has_gene_tree_pan'}  = !!($pan_member && $pan_member->has_GeneTree);
        $availability->{"has_$_"}             = $counts->{$_} for qw(alignments_pan paralogs_pan orthologs_pan);
      }
    } elsif ($obj->isa('Bio::EnsEMBL::Compara::Family')) {
      $availability->{'family'} = 1;
    }
    $self->{'_availability'} = $availability;
  }

  return $self->{'_availability'};
}

sub counts {
  my ($self, $member, $pan_member) = @_;
  my $obj = $self->Obj;

  return {} unless $obj->isa('Bio::EnsEMBL::Gene');
  
  my $key = sprintf '::COUNTS::GENE::%s::%s::%s::', $self->species, $self->hub->core_param('db'), $self->hub->core_param('g');
  my $counts = $self->{'_counts'};
  $counts ||= $MEMD->get($key) if $MEMD;
  
  if (!$counts) {
    $counts = {
## VB      
      expression     => $self->count_gene_oligos,
      pubmed         => $self->count_pubmed,  
      pathways       => $self->count_pathways,  
## /VB        
      transcripts        => scalar @{$obj->get_all_Transcripts},
      exons              => scalar @{$obj->get_all_Exons},
#      similarity_matches => $self->count_xrefs
      similarity_matches => $self->get_xref_available,
      operons => 0,
      alternative_alleles =>  scalar @{$self->get_alt_alleles},
    };
    if ($obj->feature_Slice->can('get_all_Operons')){
      $counts->{'operons'} = scalar @{$obj->feature_Slice->get_all_Operons};
    }
    $counts->{structural_variation} = 0;
    if ($self->database('variation')){ 
      my $vdb = $self->species_defs->get_config($self->species,'databases')->{'DATABASE_VARIATION'};
      $counts->{structural_variation} = $vdb->{'tables'}{'structural_variation'}{'rows'};
      $counts->{phenotypes} = $self->get_phenotype;
    }
    if ($member) {
      $counts->{'orthologs'}  = $member->number_of_orthologues;
      $counts->{'paralogs'}   = $member->number_of_paralogues;
      $counts->{'families'}   = $member->number_of_families;
    }
    my $alignments = $self->count_alignments;
    $counts->{'alignments'} = $alignments->{'all'} if $self->get_db eq 'core';
    $counts->{'pairwise_alignments'} = $alignments->{'pairwise'} + $alignments->{'patch'};

    ## Add pan-compara if available 
    if ($pan_member) {
      my $compara_dbh = $self->database('compara_pan_ensembl')->dbc->db_handle;

      $counts->{'orthologs_pan'}  = $pan_member->number_of_orthologues;
      $counts->{'paralogs_pan'}   = $pan_member->number_of_paralogues;
      $counts->{'families_pan'}   = $pan_member->number_of_families;

      $counts->{'alignments_pan'} = $self->count_alignments('DATABASE_COMPARA_PAN_ENSEMBL')->{'all'} if $self->get_db eq 'core';
    }    

    ## Add counts from plugins
    $counts = {%$counts, %{$self->_counts($member, $pan_member)}};

    $MEMD->set($key, $counts, undef, 'COUNTS') if $MEMD;
    $self->{'_counts'} = $counts;
  }
  
  return $counts;
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

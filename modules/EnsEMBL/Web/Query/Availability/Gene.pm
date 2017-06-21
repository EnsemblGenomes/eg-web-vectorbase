package EnsEMBL::Web::Query::Availability::Gene;

use strict;
use warnings;

use previous qw(get);

## VB - extend add counts and availability

sub get {
  my ($self, $args) = @_;

  my $get    = $self->PREV::get($args);
  my $avail  = $get->[0];
  my $counts = $avail->{counts};
  
  $avail->{has_pathways}   = $counts->{pathways}   = $self->_count_pathways($args);
  $avail->{pubmed}         = $counts->{pubmed}     = $self->_count_pubmed($args);
  
  return $get;
}

sub _count_pubmed {
  my ($self, $args) = @_;

  my $dbc = $self->database_dbc($args->{'species'}, $args->{'type'});
  return 0 unless $dbc;

  my $sql = qq{
    SELECT count(distinct(ox.xref_id))
    FROM object_xref ox, xref x, external_db edb
    WHERE ox.xref_id = x.xref_id
      AND x.external_db_id = edb.external_db_id
      AND edb.db_name = 'PUBMED'
      AND ox.ensembl_object_type = 'Gene'
      AND ox.ensembl_id = ?
  };

  my $sth = $dbc->prepare($sql);
  $sth->execute($args->{'gene'}->dbID);                                                                                                                                                                                                           
  
  return $sth->fetchall_arrayref->[0][0];
}

sub _count_pathways {
 my ($self, $args) = @_;

  my $dbc = $self->database_dbc($args->{'species'}, $args->{'type'});
  return 0 unless $dbc;

  my $sql = qq{
    SELECT count(distinct(ox.xref_id))
    FROM object_xref ox, xref x, external_db edb
    WHERE ox.xref_id = x.xref_id
      AND x.external_db_id = edb.external_db_id
      AND edb.db_name = 'KEGG'
      AND ox.ensembl_object_type = 'Gene'
      AND ox.ensembl_id = ?
  };

  my $sth = $dbc->prepare($sql);
  $sth->execute($args->{'gene'}->dbID);                                                                                                                                                                                                           
  
  return $sth->fetchall_arrayref->[0][0];
}


## /VB


1;

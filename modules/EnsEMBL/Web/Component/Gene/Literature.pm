package EnsEMBL::Web::Component::Gene::Literature;
use strict;
use base qw(EnsEMBL::Web::Component::Gene);
use Data::Dumper;
use URI::Escape;
use JSON;
use LWP::UserAgent;

sub content {
  my $self         = shift;
  my $hub          = $self->hub;
  my $gene_id      = $self->hub->param('g');
  my $species_defs = $hub->species_defs;
  my $html;
  
  my ($articles, $error) = $self->europe_pmc_articles($self->pubmed_ids);

  if ($error) {
  
    $html .= $self->_info_panel('error', 'Failed to fetch articles from Europe PubMed Central', $error);
  
  } else {

    my $table = $self->new_table(
      [
        { key => 'pubmed_id', title => 'PubMed&nbsp;ID', width => '6%',  align => 'left', sort => 'html' },
        { key => 'title',     title => 'Title',          width => '50%', align => 'left', sort => 'string' },
        { key => 'authors',   title => 'Authors',        width => '22%', align => 'left', sort => 'html' },
        { key => 'journal',   title => 'Journal',        width => '22%', align => 'left', sort => 'string' },
      ], 
      [], 
      { 
        class      => 'no_col_toggle',
        data_table => 1, 
        exportable => 0,
      }
    );

    foreach (@$articles) {
      my @authors = split /\s*,\s+|\s*and\s+/, $_->{authorString};
      @authors = map {sprintf '<a href="http://www.ncbi.nlm.nih.gov/pubmed/?term=%s">%s</a>', uri_escape($_), $_  } @authors;

      $table->add_row({
        pubmed_id => sprintf( '<a href="%s" style="white-space:nowrap">%s</a>', $hub->get_ExtURL('PUBMED', $_->{pmid}), $_->{pmid} ),
        title     => $_->{title},
        authors   => join(', ', @authors),
        journal   => sprintf '%s %s(%s) %s', $_->{journalTitle}, $_->{journalVolume}, $_->{issue}, $_->{pubYear}
      });
    }

    $html .= $table->render;  
  }

  return $html;
}

sub pubmed_ids {
  my $self    = shift;
  my $object  = $self->object;
  my $db      = $object->database('core');
  return [] unless $db;
  my $dbh     = $db->dbc->db_handle;
  my $gene_id = $object->gene->dbID;
  
  my $sql = qq{
    SELECT dbprimary_acc
    FROM object_xref ox, xref x, external_db edb
    WHERE ox.xref_id = x.xref_id
    AND x.external_db_id = edb.external_db_id
    AND edb.db_name = 'PUBMED'
    AND ox.ensembl_object_type = 'Gene'
    AND ox.ensembl_id = ?
  };

  my $ids = $dbh->selectcol_arrayref($sql, undef, $gene_id);                                                                                                                                                                                          
  
  return $ids;
}

sub europe_pmc_articles {
  my ($self, $pubmed_ids) = @_;
  my $articles = [];
  my $error    = 0;
  my $query    = sprintf '(EXT_ID:%s)', join ' OR EXT_ID:', @$pubmed_ids;
  my $uri      = 'https://www.ebi.ac.uk/europepmc/webservices/rest/search/format=json&query=' . uri_escape($query);

  my $response = $self->_user_agent->get($uri);

  if ($response->is_success) {
    eval { $articles = from_json($response->content)->{resultList}->{result} };
    $error = $@ if $@;
  } else {
    $error = $response->status_line;
  }

  return $articles, $error;  
}

sub _user_agent {
  my $self = shift;
  my $ua = LWP::UserAgent->new;
  $ua->agent($SiteDefs::SITE_NAME . ' ' . $SiteDefs::SITE_RELEASE_VERSION);
  $ua->env_proxy;
  return $ua;
}

1;


# $Id: Oligo.pm,v 1.6 2013-10-01 10:53:26 nl2 Exp $

package EnsEMBL::Web::ZMenu::Oligo;

use strict;

use base qw(EnsEMBL::Web::ZMenu);

sub content {
  my $self         = shift;
  my $hub          = $self->hub;
  my $id           = $hub->param('id');
  my $db           = $hub->param('fdb') || $hub->param('db') || 'core';
  my $object_type  = $hub->param('ftype');
  my $array_name   = $hub->param('array');
  my $db_adaptor   = $hub->database(lc $db);
  my $adaptor_name = "get_${object_type}Adaptor";
  my $feat_adap    = $db_adaptor->$adaptor_name; 
  my $type         = 'Individual probes:';
  my $features     = [];

  # details of each probe within the probe set on the array that are found within the slice
  my ($r_name, $r_start, $r_end) = $hub->param('r') =~ /(\w+):(\d+)-(\d+)/;
  my %probes;
  
  if ($hub->param('ptype') ne 'probe') {
    $features = $feat_adap->can('fetch_all_by_hit_name') ? $feat_adap->fetch_all_by_hit_name($id) : 
          $feat_adap->can('fetch_all_by_probeset_name') ? $feat_adap->fetch_all_by_probeset_name($id) : [];
  }
  
  if (scalar @$features == 0 && $feat_adap->can('fetch_all_by_Probe')) {
    my $probe_obj = $db_adaptor->get_ProbeAdaptor->fetch_by_array_probe_probeset_name($hub->param('array'), $id);
    
    $features = $feat_adap->fetch_all_by_Probe($probe_obj);
    
    $self->caption("Probe: $id");
  } else {
    $self->caption("Probe set: $id");
  }
## VB
  if (uc($array_name) eq 'AGSNP01') {
      if ($id =~ /^ss/) {
	  
	  # rm the ss                                                                                                                                                                                                                               
	  my $ssID = $id;
	  $ssID =~ s/^ss//;
	  
	  $self->add_entry({
	      label => 'dbSNP entry',
	      link  => "http://www.ncbi.nlm.nih.gov/projects/SNP/snp_ss.cgi?ss=$ssID",
			   });
      } else {
	  # do nothing really
      }
  } else {
      $self->add_entry({
	  label => 'VectorBase Gene Expression',
	  link  => $SiteDefs::VECTORBASE_EXPRESSION_BROWSER . "/reporter/$id",
		       });
  }
## /VB
  
  $self->add_entry({ 
    label => 'View all probe hits',
    link  => $hub->url({
      type   => 'Location',
      action => 'Genome',
      id     => $id,
      fdb    => 'funcgen',
      ftype  => $object_type,
      ptype  => $hub->param('ptype'),
      db     => 'core'
    })
  });

  foreach (@$features){ 
    my $op         = $_->probe; 
    my $of_name    = $_->probe->get_probename($array_name);
    my $of_sr_name = $_->seq_region_name;
    
    next if $of_sr_name ne $r_name;
    
    my $of_start = $_->seq_region_start;
    my $of_end   = $_->seq_region_end;
    
    next if ($of_start > $r_end) || ($of_end < $r_start);
    
    $probes{$of_name}{'chr'}   = $of_sr_name;
    $probes{$of_name}{'start'} = $of_start;
    $probes{$of_name}{'end'}   = $of_end;
    $probes{$of_name}{'loc'}   = $of_start . 'bp-' . $of_end . 'bp';
  }
  
  foreach my $probe (sort {
    $probes{$a}->{'chr'}   <=> $probes{$b}->{'chr'}   ||
    $probes{$a}->{'start'} <=> $probes{$b}->{'start'} ||
    $probes{$a}->{'stop'}  <=> $probes{$b}->{'stop'}
  } keys %probes) {
    $self->add_entry({
      type  => $type,
      label => "$probe ($probes{$probe}->{'loc'})",
    });
    
    $type = ' ';
  }
}

1;

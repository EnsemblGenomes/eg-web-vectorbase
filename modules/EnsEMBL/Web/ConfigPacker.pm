package EnsEMBL::Web::ConfigPacker;

use strict;
use warnings;
no warnings qw(uninitialized);

sub _summarise_variation_db {
  my($self,$code,$db_name) = @_;
  my $dbh     = $self->db_connect( $db_name );
  return unless $dbh;
  push @{ $self->db_tree->{'variation_like_databases'} }, $db_name;
  $self->_summarise_generic( $db_name, $dbh );
  
  # get menu config from meta table if it exists
  my $v_conf_aref = $dbh->selectall_arrayref('select meta_value from meta where meta_key = "web_config" order by meta_id asc');
  foreach my $row(@$v_conf_aref) {
    my @values = split(/\#/,$row->[0],-1);
    my ($type,$long_name,$short_name,$key,$parent) = @values;

    push @{$self->db_details($db_name)->{'tables'}{'menu'}}, {
      type       => $type,
      long_name  => $long_name,
      short_name => $short_name,
      key        => $key,
      parent     => $parent
    };
  }
  
  my $t_aref = $dbh->selectall_arrayref( 'select source_id,name,description, if(somatic_status = "somatic", 1, 0), type from source' );
#---------- Add in information about the sources from the source table
  my $temp = {map {$_->[0],[$_->[1],0]} @$t_aref};
  my $temp_description = {map {$_->[1],$_->[2]} @$t_aref};
  my $temp_somatic = { map {$_->[1],$_->[3]} @$t_aref};
  my $temp_type = { map {$_->[1], $_->[4]} @$t_aref};
  foreach my $t (qw(variation variation_synonym)) {
    my $t_aref = $dbh->selectall_arrayref( "select source_id,count(*) from $t group by source_id" );
    foreach (@$t_aref) {
      $temp->{$_->[0]}[1] += $_->[1];
    }
  }
  $self->db_details($db_name)->{'tables'}{'source'}{'counts'} = { map {@$_} values %$temp};
  $self->db_details($db_name)->{'tables'}{'source'}{'descriptions'} = \%$temp_description;
  $self->db_details($db_name)->{'tables'}{'source'}{'somatic'} = \%$temp_somatic;
  $self->db_details($db_name)->{'tables'}{'source'}{'type'} = \%$temp_type;

#---------- Store dbSNP version 
 my $s_aref = $dbh->selectall_arrayref( 'select version from source where name = "dbSNP"' );
 foreach (@$s_aref){
    my ($version) = @$_;
    $self->db_details($db_name)->{'dbSNP_VERSION'} = $version;   
  }

#--------- Does this species have structural variants?
 my $sv_aref = $dbh->selectall_arrayref('select count(*) from structural_variation');
 foreach (@$sv_aref){
    my ($count) = @$_;
    $self->db_details($db_name)->{'STRUCTURAL_VARIANT_COUNT'} = $count;
 }

#---------- Add in information about the display type from the sample table
   my $d_aref = [];
   if ($self->db_details($db_name)->{'tables'}{'sample'}) {
      $d_aref = $dbh->selectall_arrayref( "select name, display from sample where display not like 'UNDISPLAYABLE'" );
   } else {
      my $i_aref = $dbh->selectall_arrayref( "select name, display from individual where display not like 'UNDISPLAYABLE'" );
      push @$d_aref, @$i_aref;
      my $p_aref = $dbh->selectall_arrayref( "select name, display from population where display not like 'UNDISPLAYABLE'" );
      push @$d_aref, @$p_aref; 
   }
   my (@default, $reference, @display, @ld);
   foreach (@$d_aref){
     my  ($name, $type) = @$_;  
     if ($type eq 'REFERENCE') { $reference = $name;}
     elsif ($type eq 'DISPLAYABLE'){ push(@display, $name); }
     elsif ($type eq 'DEFAULT'){ push (@default, $name); }
     elsif ($type eq 'LD'){ push (@ld, $name); } 
   }
   $self->db_details($db_name)->{'tables'}{'sample.reference_strain'} = $reference;
   $self->db_details($db_name)->{'REFERENCE_STRAIN'} = $reference; 
   $self->db_details($db_name)->{'meta_info'}{'sample.default_strain'} = \@default;
   $self->db_details($db_name)->{'DEFAULT_STRAINS'} = \@default;  
   $self->db_details($db_name)->{'meta_info'}{'sample.display_strain'} = \@display;
   $self->db_details($db_name)->{'DISPLAY_STRAINS'} = \@display; 
   $self->db_details($db_name)->{'LD_POPULATIONS'} = \@ld;

## VB - add description lookup
  
  my $name_desc = $dbh->selectall_arrayref( "select name, description from individual" );
  $self->db_details($db_name)->{'DISPLAY_STRAIN_DESCRIPTION'}->{$_->[0]} = $_->[1] for @$name_desc;

##

#---------- Add in strains contained in read_coverage_collection table
  if ($self->db_details($db_name)->{'tables'}{'read_coverage_collection'}){
    my $r_aref = $dbh->selectall_arrayref(
        'select distinct i.name, i.individual_id
        from individual i, read_coverage_collection r
        where i.individual_id = r.sample_id' 
     );
     my @strains;
     foreach my $a_aref (@$r_aref){
       my $strain = $a_aref->[0] . '_' . $a_aref->[1];
       push (@strains, $strain);
     }
     if (@strains) { $self->db_details($db_name)->{'tables'}{'read_coverage_collection_strains'} = join(',', @strains); } 
  }

#--------- Add in structural variation information
  my $v_aref = $dbh->selectall_arrayref("select s.name, count(*), s.description from structural_variation sv, source s, attrib a where sv.source_id=s.source_id and sv.class_attrib_id=a.attrib_id and a.value!='probe' and sv.somatic=0 group by sv.source_id");
  my %structural_variations;
  my %sv_descriptions;
  foreach (@$v_aref) {
   $structural_variations{$_->[0]} = $_->[1];    
   $sv_descriptions{$_->[0]} = $_->[2];
  }
  $self->db_details($db_name)->{'tables'}{'structural_variation'}{'counts'} = \%structural_variations;
  $self->db_details($db_name)->{'tables'}{'structural_variation'}{'descriptions'} = \%sv_descriptions;

#--------- Add in copy number variant probes information
  my $cnv_aref = $dbh->selectall_arrayref("select s.name, count(*), s.description from structural_variation sv, source s, attrib a where sv.source_id=s.source_id and sv.class_attrib_id=a.attrib_id and a.value='probe' group by sv.source_id");
  my %cnv_probes;
  my %cnv_probes_descriptions;
  foreach (@$cnv_aref) {
   $cnv_probes{$_->[0]} = $_->[1];    
   $cnv_probes_descriptions{$_->[0]} = $_->[2];
  }
  $self->db_details($db_name)->{'tables'}{'structural_variation'}{cnv_probes}{'counts'} = \%cnv_probes;
  $self->db_details($db_name)->{'tables'}{'structural_variation'}{cnv_probes}{'descriptions'} = \%cnv_probes_descriptions;
#--------- Add in somatic structural variation information
  my $som_sv_aref = $dbh->selectall_arrayref("select s.name, count(*), s.description from structural_variation sv, source s, attrib a where sv.source_id=s.source_id and sv.class_attrib_id=a.attrib_id and a.value!='probe' and sv.somatic=1 group by sv.source_id");
  my %somatic_sv;
  my %somatic_sv_descriptions;
  foreach (@$som_sv_aref) {
   $somatic_sv{$_->[0]} = $_->[1];    
   $somatic_sv_descriptions{$_->[0]} = $_->[2];
  }
  $self->db_details($db_name)->{'tables'}{'structural_variation'}{'somatic'}{'counts'} = \%somatic_sv;
  $self->db_details($db_name)->{'tables'}{'structural_variation'}{'somatic'}{'descriptions'} = \%somatic_sv_descriptions;  
#--------- Add in structural variation study information
  my $study_sv_aref = $dbh->selectall_arrayref("select distinct st.name, st.description from structural_variation sv, study st where sv.study_id=st.study_id");
  my %study_sv_descriptions;
  foreach (@$study_sv_aref) {    
   $study_sv_descriptions{$_->[0]} = $_->[1];
  }
  $self->db_details($db_name)->{'tables'}{'structural_variation'}{'study'}{'descriptions'} = \%study_sv_descriptions;    
#--------- Add in Variation set information
  # First get all toplevel sets
  my (%super_sets, %sub_sets, %set_descriptions);

  my $st_aref = $dbh->selectall_arrayref('
    select vs.variation_set_id, vs.name, vs.description, a.value
      from variation_set vs, attrib a
      where not exists (
        select * 
          from variation_set_structure vss
          where vss.variation_set_sub = vs.variation_set_id
        )
        and a.attrib_id = vs.short_name_attrib_id'
  );
  
  # then get subsets foreach toplevel set
  foreach (@$st_aref) {
    my $set_id = $_->[0];
    
    $super_sets{$set_id} = {
      name        => $_->[1],
      description => $_->[2],
      short_name  => $_->[3],
      subsets     => [],
    };
  
  $set_descriptions{$_->[3]} = $_->[2];
    
    my $ss_aref = $dbh->selectall_arrayref("
      select vs.variation_set_id, vs.name, vs.description, a.value 
        from variation_set vs, variation_set_structure vss, attrib a
        where vss.variation_set_sub = vs.variation_set_id 
          and a.attrib_id = vs.short_name_attrib_id
          and vss.variation_set_super = $set_id"  
    );

    foreach my $sub_set (@$ss_aref) {
      push @{$super_sets{$set_id}{'subsets'}}, $sub_set->[0];
      
      $sub_sets{$sub_set->[0]} = {
        name        => $sub_set->[1],
        description => $sub_set->[2],
        short_name  => $sub_set->[3],
      };
    } 
  }
  
  # just get all descriptions
  my $vs_aref = $dbh->selectall_arrayref("
	SELECT a.value, vs.description
	FROM variation_set vs, attrib a
	WHERE vs.short_name_attrib_id = a.attrib_id
  ");
  
  $set_descriptions{$_->[0]} = $_->[1] for @$vs_aref;

  $self->db_details($db_name)->{'tables'}{'variation_set'}{'supersets'}    = \%super_sets;  
  $self->db_details($db_name)->{'tables'}{'variation_set'}{'subsets'}      = \%sub_sets;
  $self->db_details($db_name)->{'tables'}{'variation_set'}{'descriptions'} = \%set_descriptions;
  
#--------- Add in phenotype information
  if ($code !~ /variation_private/i) {
    my $pf_aref = $dbh->selectall_arrayref(qq{
      SELECT pf.type, GROUP_CONCAT(DISTINCT s.name), count(pf.phenotype_feature_id)
      FROM phenotype_feature pf, source s
      WHERE pf.source_id=s.source_id AND pf.is_significant=1 AND pf.type!='SupportingStructuralVariation'
      GROUP BY pf.type
    });

    for(@$pf_aref) {
      $self->db_details($db_name)->{'tables'}{'phenotypes'}{'rows'} += $_->[2];
      $self->db_details($db_name)->{'tables'}{'phenotypes'}{'types'}{$_->[0]}{'count'} = $_->[2];
      $self->db_details($db_name)->{'tables'}{'phenotypes'}{'types'}{$_->[0]}{'sources'} = $_->[1];
    }
  }

#--------- Add in somatic mutation information
  my %somatic_mutations;
	# Somatic source(s)
  my $sm_aref =  $dbh->selectall_arrayref(
    'select distinct(p.description), pf.phenotype_id, s.name 
     from phenotype p, phenotype_feature pf, source s, study st
     where p.phenotype_id=pf.phenotype_id and pf.study_id = st.study_id
     and st.source_id=s.source_id and s.somatic_status = "somatic"'
  );
  foreach (@$sm_aref){ 
    $somatic_mutations{$_->[2]}->{$_->[0]} = $_->[1] ;
  } 
  
	# Mixed source(s)
	my $mx_aref = $dbh->selectall_arrayref(
	  'select distinct(s.name) from variation v, source s 
		 where v.source_id=s.source_id and s.somatic_status = "mixed"'
	);
	foreach (@$mx_aref){ 
    $somatic_mutations{$_->[0]}->{'none'} = 'none' ;
  } 
	
  $self->db_details($db_name)->{'SOMATIC_MUTATIONS'} = \%somatic_mutations;

  ## Do we have SIFT and/or PolyPhen predictions?
  my $prediction_aref = $dbh->selectall_arrayref(
    'select distinct(a.value) from attrib a, protein_function_predictions p where a.attrib_id = p.analysis_attrib_id'
  );
  foreach (@$prediction_aref) {
    if ($_->[0] =~ /sift/i) {
      $self->db_details($db_name)->{'SIFT'} = 1;
    }
    if ($_->[0] =~ /^polyphen/i) {
      $self->db_details($db_name)->{'POLYPHEN'} = 1;
    }
  }
  
  # get possible values from attrib tables
  @{$self->db_details($db_name)->{'SIFT_VALUES'}} = map {$_->[0]} @{$dbh->selectall_arrayref(
    'SELECT a.value FROM attrib a, attrib_type t WHERE a.attrib_type_id = t.attrib_type_id AND t.code = "sift_prediction";'
  )};
  @{$self->db_details($db_name)->{'POLYPHEN_VALUES'}} = map {$_->[0]} @{$dbh->selectall_arrayref(
    'SELECT a.value FROM attrib a, attrib_type t WHERE a.attrib_type_id = t.attrib_type_id AND t.code = "polyphen_prediction";'
  )};

  $dbh->disconnect();
}

1;

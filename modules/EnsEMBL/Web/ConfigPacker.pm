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

sub _summarise_funcgen_db {
  my ($self, $db_key, $db_name) = @_;
  my $dbh = $self->db_connect($db_name);
  
  return unless $dbh;
  
  push @{$self->db_tree->{'funcgen_like_databases'}}, $db_name;
  
  $self->_summarise_generic($db_name, $dbh);
  
  ## Grab each of the analyses - will use these in a moment
  my $t_aref = $dbh->selectall_arrayref(
    'select a.analysis_id, a.logic_name, a.created, ad.display_label, ad.description, ad.displayable, ad.web_data
    from analysis a left join analysis_description as ad on a.analysis_id=ad.analysis_id'
  );
  
  my $analysis = {};
  
  foreach my $a_aref (@$t_aref) {
    my $desc;
    { no warnings; $desc = eval($a_aref->[4]) || $a_aref->[4]; }    
    (my $web_data = $a_aref->[6]) =~ s/^[^{]+//; ## Strip out "crap" at front and end! probably some q(')s
    $web_data     =~ s/[^}]+$//;
    $web_data     = eval($web_data) || {};
    
    $analysis->{$a_aref->[0]} = {
      'logic_name'  => $a_aref->[1],
      'name'        => $a_aref->[3],
      'description' => $desc,
      'displayable' => $a_aref->[5],
      'web_data'    => $web_data
    };
  }

  ## Get analysis information about each feature type
  foreach my $table (qw(probe_feature feature_set result_set regulatory_build)) {
    my $res_aref = $dbh->selectall_arrayref("select analysis_id, count(*) from $table group by analysis_id");
    
    foreach my $T (@$res_aref) {
      my $a_ref = $analysis->{$T->[0]}; #|| ( warn("Missing analysis entry $table - $T->[0]\n") && next );
      my $value = {
        'name'  => $a_ref->{'name'},
        'desc'  => $a_ref->{'description'},
        'disp'  => $a_ref->{'displayable'},
        'web'   => $a_ref->{'web_data'},
        'count' => $T->[1]
      }; 
      
      $self->db_details($db_name)->{'tables'}{$table}{'analyses'}{$a_ref->{'logic_name'}} = $value;
    }
  }

###
### Store the external feature sets available for each species
###
  my @feature_sets;
  my $f_aref = $dbh->selectall_arrayref(
    "select name
      from feature_set
      where type = 'external'"
  );
  foreach my $F ( @$f_aref ){ push (@feature_sets, $F->[0]); }  
  $self->db_tree->{'databases'}{'DATABASE_FUNCGEN'}{'FEATURE_SETS'} = \@feature_sets;

### Find details of epigenomes, distinguishing those that are present in 
### the current regulatory build
  my $c_aref =  $dbh->selectall_arrayref(
    'select
      distinct epigenome.name, epigenome.epigenome_id, 
                epigenome.display_label
        from regulatory_build 
      join regulatory_build_epigenome using (regulatory_build_id) 
      join epigenome using (epigenome_id)
      where regulatory_build.is_current=1
     '
  );
  foreach my $row (@$c_aref) {
    my $cell_type_key =  $row->[0] .':'. $row->[1];
    $self->db_details($db_name)->{'tables'}{'cell_type'}{'names'}{$cell_type_key} = $row->[2];
    $self->db_details($db_name)->{'tables'}{'cell_type'}{'ids'}{$cell_type_key} = 1;
  }

  ## Now look for cell lines that _aren't_ in the build
  $c_aref = $dbh->selectall_arrayref(
    'select
        epigenome.name, epigenome.epigenome_id, epigenome.display_label
      from epigenome 
      left join regulatory_build_epigenome as rbe 
        on rbe.epigenome_id = epigenome.epigenome_id
      where rbe.regulatory_build_id is null
     '
  );
  foreach my $row (@$c_aref) {
    my $cell_type_key =  $row->[0] .':'. $row->[1];
    $self->db_details($db_name)->{'tables'}{'cell_type'}{'names'}{$cell_type_key} = $row->[2];
    $self->db_details($db_name)->{'tables'}{'cell_type'}{'ids'}{$cell_type_key} = 0;
  }
  
#---------- Additional queries - by type...

#
# * Oligos
#

## VB - add probe descriptions
  $t_aref = $dbh->selectall_arrayref(
    'select a.vendor, a.name, a.array_id, a.description
       from array a, array_chip c, status s, status_name sn where  sn.name="DISPLAYABLE" 
       and sn.status_name_id=s.status_name_id and s.table_name="array" and s.table_id=a.array_id 
       and a.array_id=c.array_id
    '       
  );
  my $sth = $dbh->prepare(
    'select pf.probe_feature_id
       from array_chip ac, probe p, probe_feature pf, seq_region sr, coord_system cs
       where ac.array_chip_id=p.array_chip_id and p.probe_id=pf.probe_id  
       and pf.seq_region_id=sr.seq_region_id and sr.coord_system_id=cs.coord_system_id 
       and cs.is_current=1 and ac.array_id = ?
       limit 1 
    '
  );
  foreach my $row (@$t_aref) {
    my $array_name = $row->[0] .':'. $row->[1];
    my $description = $row->[3];
    $sth->bind_param(1, $row->[2]);
    $sth->execute;
    my $count = $sth->fetchrow_array();# warn $array_name ." ". $count;
    if( exists $self->db_details($db_name)->{'tables'}{'oligo_feature'}{'arrays'}{$array_name} ) {
      warn "FOUND";
    }
    $self->db_details($db_name)->{'tables'}{'oligo_feature'}{'arrays'}{$array_name} = $count ? 1 : 0;
    $self->db_details($db_name)->{'tables'}{'oligo_feature'}{'descriptions'}{$array_name} = $description;
  }
  $sth->finish;
## /VB

  ## Segmentations are stored differently, now they are in flat-files
  my $res_cell = $dbh->selectall_arrayref(
      qq(
	        select 
	          logic_name, 
	          epigenome_id,
	          epigenome.display_label,
	          epigenome.name,
            displayable,
            segmentation_file.name
	        from segmentation_file
	          join epigenome using (epigenome_id)
	          join analysis using (analysis_id)
            join analysis_description using (analysis_id)
      )
  );

  foreach my $C (@$res_cell) {
    my $key = $C->[0].':'.$C->[3];
    my $value = {
      name => qq($C->[2] Regulatory Segmentation),
      desc => qq($C->[2] <a href="/info/genome/funcgen/regulatory_segmentation.html">segmentation state analysis</a>"),
      disp => $C->[4],
      'web' => {
          celltype      => $C->[1],
          celltypename  => $C->[2],
          'colourset'   => 'fg_segmentation_features',
          'display'     => 'off',
          'key'         => "seg_$key",
          'seg_name'    => $C->[5],
          'type'        => 'fg_segmentation_features'
      },
      count => 1,
    };
    $self->db_details($db_name)->{'tables'}{'segmentation'}{$key} = $value;
  }

  ## Methylation tracks - now in files
  my $m_aref = $dbh->selectall_arrayref(qq(
      select 
        eff.name,
        a.display_label,
        a.description,
        epigenome.name,
        g.name
      from external_feature_file eff
        join analysis_description a using (analysis_id)
        join epigenome using (epigenome_id)
        join feature_type using (feature_type_id)
        join experiment using (epigenome_id)
        join experimental_group g using (experimental_group_id)
    )
  );
 foreach (@$m_aref) {
    my ($id, $a_name, $a_desc, $c_desc, $group) = @$_;

    my $name = "$c_desc $a_name";
    $name .= " $group" if $group;
    my $desc = "$c_desc cell line: $a_desc";
    $desc .= " ($group group)." if $group;    
    $self->db_details($db_name)->{'tables'}{'methylation'}{$id} = {
                                                                    name        => $name,
                                                                    description => $desc,
                                                                  };
  }

  ## New CRISPR tracks
  my $cr_aref = $dbh->selectall_arrayref(qq(
      select 
        eff.name,
        ad.display_label,
        ad.description
      from external_feature_file eff
        join analysis a using (analysis_id)
        join analysis_description ad using (analysis_id)
      where
        a.logic_name = "Crispr"
    )
  );

  foreach (@$cr_aref) {
    my ($id, $name, $desc) = @$_;

    $self->db_details($db_name)->{'tables'}{'crispr'}{$id} = {
                                                                    name        => $name,
                                                                    description => $desc,
                                                                  };
  }

  ## Matrices
  my %sets = ('core' => '"Open Chromatin", "Transcription Factor"', 'non_core' => '"Histone", "Polymerase"');

  while (my ($set, $classes) = each(%sets)) {
    my $ft_aref = $dbh->selectall_arrayref(qq(
      select 
        epigenome.display_label, 
        feature_set.feature_type_id, 
        feature_set.feature_set_id
      from 
        epigenome 
      join feature_set using (epigenome_id) 
      join feature_type using (feature_type_id) 
      where 
        class in ($classes) 
    ));

    my $data;
    foreach my $row (@$ft_aref) {
      if ($set eq 'core') {
        $data->{$row->[0]}{$row->[1]} = $row->[2];
      }
      else {
        $data->{$row->[0]}{$row->[1]} = 1;
      }
    }
    $self->db_details($db_name)->{'tables'}{'feature_types'}{$set} = $data;
  }

  $dbh->disconnect();
}

1;

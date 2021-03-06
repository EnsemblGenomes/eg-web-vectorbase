# $Id: contigviewbottom.pm,v 1.9 2014-01-23 16:25:18 nl2 Exp $

package EnsEMBL::Web::ImageConfig::contigviewbottom;

use strict;

use previous qw(init_cacheable);

sub init_cacheable {
  my $self = shift;
  
  $self->create_menus(qw(
    sequence
    marker
    trans_associated
    transcript
    prediction
    dna_align_cdna
    dna_align_est
    dna_align_rna
    dna_align_other
    protein_align
    protein_feature
    rnaseq
    rnaseq_align
    ditag
    simple
    genome_attribs
    misc_feature
    variation
    recombination
    somatic
    functional
    multiple_align
    conservation
    pairwise_blastz
    pairwise_tblat
    pairwise_other
    dna_align_compara
    cap
    oligo
    repeat
    cap

    chromatin_binding
    pb_intron_branch_point
    polya_sites 
    replication_profiling
    regulatory_elements
    tss
    transcriptome
    nucleosome
    dna_methylation
    histone_mod 

    wheat_alignment      
    wheat_assembly       
    wheat_transcriptomics
    wheat_ests           
    rnaseq_cultivar      
    rnaseq_tissue        
    resequencing  

    external_data
    user_data
    decorations
    information
  ));

  $self->PREV::init_cacheable(@_);
}

1;

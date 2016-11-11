package EnsEMBL::Web::ImageConfig::MultiBottom;

use previous qw(init_cacheable);

sub init_cacheable {
  my $self = shift;

  $self->create_menus(qw(
    sequence
    marker
    transcript
    prediction
    dna_align_cdna
    dna_align_est 
    dna_align_rna 
    dna_align_other 
    protein_align
    rnaseq
    rnaseq_align
    simple
    misc_feature
    variation 
    somatic 
    functional
    cap
    oligo
    repeat
    user_data
    decorations 
    information 
  ));

  $self->PREV::init_cacheable(@_);
}

1;

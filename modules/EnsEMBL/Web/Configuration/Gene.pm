package EnsEMBL::Web::Configuration::Gene;
use strict;
use warnings;

sub modify_tree {
  my $self = shift;
  my $hub = $self->hub;
  my $species = $hub->species;
  my $species_defs = $hub->species_defs;
  my $object = $self->object;

## VB
  $self->delete_node($_) for (qw(Alleles SecondaryStructure Family ExpressionAtlas));
##

  my $summary = $self->get_node('Summary');

#  my $splice = $self->get_node('Splice');
#  $splice->set('components', [qw( image EnsEMBL::Web::Component::Gene::GeneSpliceImageNew )]);

  return unless ($self->object || $hub->param('g'));

  my $gene_adaptor = $hub->get_adaptor('get_GeneAdaptor', 'core', $species);
  my $gene   = $self->object ? $self->object->gene : $gene_adaptor->fetch_by_stable_id($hub->param('g'));  

  return if ref $gene eq 'Bio::EnsEMBL::ArchiveStableId';

  my @transcripts  = sort { $a->start <=> $b->start } @{ $gene->get_all_Transcripts || [] };
  my $transcript   = @transcripts > 0 ? $transcripts[0] : undef;

  my $region = $hub->param('r');
  my ($reg_name, $start, $end) = $region =~ /(.+?):(\d+)-(\d+)/ ? $region =~ /(.+?):(\d+)-(\d+)/ : (undef, undef, undef);

  if ($transcript) {
    my @exons        = sort {$a->start <=> $b->start} @{ $transcript->get_all_Exons || [] };
    if (@exons > 0) {
      if (defined( $transcript->coding_region_start ) && defined( $transcript->coding_region_end) ) {
        my $cover_next_e = 0;
        foreach my $e (@exons) {
    next if $e->start <= $transcript->coding_region_start && $e->end <= $transcript->coding_region_start;
          if (!$cover_next_e) {
            $start = $e->start <= $transcript->coding_region_start ? $transcript->coding_region_start : $e->start;
            $end   = $e->end   >= $transcript->coding_region_end   ? $transcript->coding_region_end   : $e->end;
            if (($end > $start) && ($end - $start + 1 < 200)) {
        $cover_next_e = 1;
            } 
    } else {
            $end   = $e->end   >= $transcript->coding_region_end   ? $transcript->coding_region_end   : $e->end;
            $cover_next_e = 0 unless ($end - $start + 1 < 200);
          }  
          last unless $cover_next_e;
        }
      } else {
        my $exon = $exons[0];
        ($start, $end) = ($exon->start, $exon->end); 
      }
    }
  }

## VB - VB-3324 availability check doesn't always seem to work for VB
##      so revert to default ensembl behaviour
  #my $evidence_node = $self->get_node('Evidence');
  #$evidence_node->set('caption', 'Supporting evidence ([[counts::gene_supporting_evidence]])');
  #$evidence_node->set('availability', 'gene has_gene_supporting_evidence');
##

  my $compara_menu  = $self->get_node('Compara');
  my $genetree = $self->get_node('Compara_Tree');
  
  $genetree->set('components', [qw(
    tree_summary EnsEMBL::Web::Component::Gene::ComparaTreeSummary
    image EnsEMBL::Web::Component::Gene::ComparaTree
				   )
				]);

## VB
  my $expression_node = $self->create_node('GeneExpressionReporters', 'Expression report',
    [], { 'availability' => 'gene has_expression', 'url' => $SiteDefs::VECTORBASE_EXPRESSION_BROWSER . "/gene/" . $self->object->param('g'), 'raw' => 1 }
  );

  my $regulation_node = $self->get_node('Regulation');
  $regulation_node->after($expression_node);
## /VB

  $genetree->before($self->create_node('Compara_Alignments', 'Genomic alignments',
    [qw(
      selector   EnsEMBL::Web::Component::Compara_AlignSliceSelector
      alignments EnsEMBL::Web::Component::Gene::Compara_Alignments
    )],
    { 'availability' => 'gene database:compara core has_alignments' }
  ));

  my $var_menu     = $self->get_node('Variation');

  my $r   = ($reg_name && $start && $end) ? $reg_name.':'.$start.'-'.$end : $gene->seq_region_name.':'.$gene->start.'-'.$gene->end;
  my $url = $hub->url({
                  type   => 'Gene',
                  action => 'Variation_Gene/Image',
                  g      => $hub->param('g') || $gene->stable_id,
                  r      => $r
  });

  my $variation_image = $self->get_node('Variation_Gene/Image');
  $variation_image->set('components', [qw( 
    imagetop EnsEMBL::Web::Component::Gene::VariationImageTop
    imagenav EnsEMBL::Web::Component::Gene::VariationImageNav
    image EnsEMBL::Web::Component::Gene::VariationImage )
             ]);
  $variation_image->set('availability', 'gene database:variation not_patch');
  $variation_image->set('url' =>  $url);

  $var_menu->append($variation_image);

  my $cdb_name = $self->hub->species_defs->COMPARA_DB_NAME || 'Comparative Genomics';

  $compara_menu->set('caption', $cdb_name);

  $compara_menu->append($self->create_subnode('Compara_Ortholog/PepSequence', 'Orthologue Sequences',
    [qw( alignment EnsEMBL::Web::Component::Gene::HomologSeq )],
           { 'availability'  => 'gene database:compara core has_orthologs', 'no_menu_entry' => 1 }
           ));


  $compara_menu->before($self->create_node('Pathways', 'Pathways',
    ['pathways', 'EnsEMBL::Web::Component::Gene::Pathways'],
    { 'availability' => 'gene has_pathways', 'concise' => 'Pathways' }
  ));

  $compara_menu->before($self->create_node("PubMed", 'PubMed ([[counts::pubmed]])',
    ['PubMed', "EnsEMBL::Web::Component::Gene::PubMed"], {
      availability => 'pubmed', 
      concise      => 'PubMed', 
    }
  ));
}

sub user_populate_tree {
    my $self        = shift;
    my $hub         = $self->hub;
    my $type        = $hub->type;
    my $all_das     = $hub->get_all_das;
    my $view_config = $hub->get_viewconfig('ExternalData');
    my @active_das  = grep { $view_config->get($_) eq 'yes' && $all_das->{$_} } $view_config->options;
    my $ext_node    = $self->tree->get_node('ExternalData');
  
    foreach (sort { lc($all_das->{$a}->caption) cmp lc($all_das->{$b}->caption) } @active_das) {
	my $source = $all_das->{$_};
    
    $ext_node->append($self->create_subnode("ExternalData/$_", $source->caption,
					    [ 'textdas', "EnsEMBL::Web::Component::${type}::TextDAS" ], {
        availability => lc $type, 
        concise      => $source->caption, 
        caption      => $source->caption, 
        full_caption => $source->label
	}
					    ));  
    }
}


1;

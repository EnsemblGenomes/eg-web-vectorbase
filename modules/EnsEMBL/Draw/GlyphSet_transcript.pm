=head1 LICENSE

Copyright [2009-2014] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package EnsEMBL::Draw::GlyphSet_transcript;

use strict;

use List::Util qw(min max);
use Clone qw(clone);

sub render_transcripts {
  my ($self, $labels) = @_;

  return $self->render_text('transcript') if $self->{'text_export'};
  
  my $config            = $self->{'config'};
  my $container         = $self->{'container'}{'ref'} || $self->{'container'};
  my $length            = $container->length;
  my $is_circular       = $container->is_circular;

  my $start_point = $container->start;
  my $end_point = $container->end;
  my $reg_end = $container->seq_region_length;
  my $addition = 0;

  my $pix_per_bp        = $self->scalex;
  my $strand            = $self->strand;
  my $selected_db       = $self->core('db');
  my $selected_trans    = $self->core('t') || $self->core('pt') ;
  my $selected_gene     = $self->my_config('g') || $self->core('g');
  my $strand_flag       = $self->my_config('strand');
  my $db                = $self->my_config('db');
  my $show_labels       = $self->my_config('show_labels');
  my $previous_species  = $self->my_config('previous_species');
  my $next_species      = $self->my_config('next_species');
  my $previous_target   = $self->my_config('previous_target');
  my $next_target       = $self->my_config('next_target');
  my $join_types        = $self->get_parameter('join_types');
  my $link              = $self->get_parameter('compara') ? $self->my_config('join') : 0;
  my $target            = $self->get_parameter('single_Transcript');
  my $target_gene       = $self->get_parameter('single_Gene');
  my $alt_alleles_col   = $self->my_colour('alt_alleles_join');
  my $y                 = 0;
  my $h                 = $self->my_config('height') || ($target ? 30 : 8); # Single transcript mode - set height to 30 - width to 8
  my $join_z            = 1000;
  my $transcript_drawn  = 0;
  my $non_coding_height = ($self->my_config('non_coding_scale')||0.75) * $h;
  my $non_coding_start  = ($h - $non_coding_height) / 2;
  my %used_colours;
  my $label_operon_genes = $self->my_config('label_operon_genes');
  my $no_operons         = $self->my_config('no_operons')||$target;
  
  my ($fontname, $fontsize) = $self->get_font_details('outertext');
  my $th = ($self->get_text_width(0, 'Xg', 'Xg', 'ptsize' => $fontsize, 'font' => $fontname))[3];
  
  $self->_init_bump;
  
  my ($genes_to_filter, $highlights, $transcripts, $exons) = $self->features;
  my %operons;
  my $genes = [];
  my %singleton_genes;
  my @operons_to_draw;

  if($no_operons || !$container->can('get_all_Operons')){
    @$genes = @$genes_to_filter;
    $genes_to_filter = [];
  }
  else{
    foreach my $gene (@$genes_to_filter) {
      my @ops = @{$gene->feature_Slice->get_all_Operons};
      unless(0<@ops){
        $singleton_genes{$gene->dbID}=$gene;
      }
    }
    # Don't restrict by logic name as we don't know the logic names for the operons
    # this may need revisiting in future if we have operons from multiple sources
    #foreach my $_logic_name(@{$self->my_config('logic_names')||[]}){
      #my @ops = @{$container->get_all_Operons($_logic_name,undef,1)};
      my @ops = @{$container->get_all_Operons};
      foreach my $opn (@ops){
        next if ($operons{$opn->dbID});
        $opn = $opn->transfer($container);
        $operons{$opn->dbID}=1;
        push(@operons_to_draw,$opn);
        foreach my $ots(@{$opn->get_all_OperonTranscripts}){
          foreach my $gene(@{$ots->get_all_Genes}){
            delete $singleton_genes{$gene->dbID};
          }
        }
      }
    #}
    @$genes = map {$singleton_genes{$_}} keys %singleton_genes;
  }

## EG
  # copy genes that cross the origin so that they are drawn on both sides
  # HACK: set a flag on the copied object so we know that we should draw it's exons 
  # in the translated position
  if ($is_circular) {
    foreach my $gene (grep {$_->start < 0} @$genes) {
      my $copy = clone($gene);
      $copy->{_draw_translated} = 1;
      push @$genes, $copy;
    }
  }
##    
  
  foreach my $gene (@$genes) {
    my $gene_strand    = $gene->strand;
    my $gene_stable_id = $gene->can('stable_id') ? $gene->stable_id || $gene->dbID : $gene->dbID;
    
    next if $gene_strand != $strand && $strand_flag eq 'b'; # skip features on wrong strand
    next if $target_gene && $gene_stable_id ne $target_gene;
    
    my (%tags, @gene_tags, $tsid);
    
    if ($link && $gene_stable_id) {
      my $alt_alleles = $gene->get_all_alt_alleles;
      my $alltrans    = $gene->get_all_Transcripts; # vega stuff to link alt-alleles on longest transcript
      my @s_alltrans  = sort { $a->length <=> $b->length } @$alltrans;
      my $long_trans  = pop @s_alltrans;
      my @transcripts;
      
      $tsid = $long_trans->stable_id;
      
      foreach my $gene (@$alt_alleles) {
        my $vtranscripts = $gene->get_all_Transcripts;
        my @sorted_trans = sort { $a->length <=> $b->length } @$vtranscripts;
        push @transcripts, (pop @sorted_trans);
      }
      

      if ($previous_species) {
        my ($peptide_id, $homologues, $homologue_genes) = $self->get_gene_joins($gene, $previous_species, $join_types, 'ENSEMBLGENE');
        
        if ($peptide_id) {
          push @{$tags{$peptide_id}}, map {[ "$_->[0]:$peptide_id",     $_->[1] ]} @$homologues;
          push @{$tags{$peptide_id}}, map {[ "$gene_stable_id:$_->[0]", $_->[1] ]} @$homologue_genes;
        }
        
        push @gene_tags, map { join '=', $_->stable_id, $tsid } @{$self->filter_by_target(\@transcripts, $previous_target)};
        
        for (@$homologues) {
          $self->{'legend'}{'gene_legend'}{'joins'}{'priority'} ||= 1000;
          $self->{'legend'}{'gene_legend'}{'joins'}{'legend'}{$_->[2]} = $_->[1];
        }
      }
      
      if ($next_species) {
        my ($peptide_id, $homologues, $homologue_genes) = $self->get_gene_joins($gene, $next_species, $join_types, 'ENSEMBLGENE');
        
        if ($peptide_id) {
          push @{$tags{$peptide_id}}, map {[ "$peptide_id:$_->[0]",     $_->[1] ]} @$homologues;
          push @{$tags{$peptide_id}}, map {[ "$_->[0]:$gene_stable_id", $_->[1] ]} @$homologue_genes;
        }
        
        push @gene_tags, map { join '=', $tsid, $_->stable_id } @{$self->filter_by_target(\@transcripts, $next_target)};
        
        for (@$homologues) {
          $self->{'legend'}{'gene_legend'}{'joins'}{'priority'} ||= 1000;
          $self->{'legend'}{'gene_legend'}{'joins'}{'legend'}{$_->[2]} = $_->[1];
        }
      }
    }
    
    my @sorted_transcripts = map $_->[1], sort { $b->[0] <=> $a->[0] } map [ $_->start * $gene_strand, $_ ], @{$transcripts->{$gene_stable_id}};
    
    foreach my $transcript (@sorted_transcripts) {
## EG
      my $transcript_stable_id = $transcript->stable_id || $transcript->dbID;
      next if $transcript->start > $length || $transcript->end < 1;
      next if $target && $transcript_stable_id ne $target; # For exon_structure diagram only given transcript
      next unless $exons->{$transcript_stable_id};          # Skip if no exons for this transcript
      
      my @exons = @{$exons->{$transcript_stable_id}};
# EG     
     if($gene->adaptor and $transcript->stable_id){ # don't try this if there is no adaptor...
        # we need this - sometimes the transcript object doesn't have all the translations
        my $_tsa = $gene->adaptor->db->get_adaptor('transcript');
        $transcript = $_tsa->fetch_by_stable_id($transcript_stable_id);
        $transcript = $transcript->transfer($gene->slice);
     }
      #next if $transcript->start > $length || $transcript->end < 1;
      my @alt_translations = sort { $a->genomic_start <=> $b->genomic_start }  @{$transcript->get_all_alternative_translations};
      my $numTranslations=1+scalar @alt_translations;
      
      next if $exons[0][0]->strand != $gene_strand && $self->{'do_not_strand'} != 1; # If stranded diagram skip if on wrong strand
      next if $target && $transcript->stable_id ne $target; # For exon_structure diagram only given transcript
# /EG     
      $transcript_drawn = 1;        

      my $composite = $self->Composite({
        y      => $y,
        height => $h,
        title  => $self->title($transcript, $gene),
        href   => $self->href($gene, $transcript),
        class  => 'group',
      });

      my $colour_key = $self->colour_key($gene, $transcript);
      my $colour     = $self->my_colour($colour_key);
      my $label      = $self->my_colour($colour_key, 'text');
      $self->use_legend(\%used_colours,$colour?$colour_key:undef);

# EG
      my $coding_start = defined $transcript->coding_region_start ? $transcript->coding_region_start : -1e6;
      my $coding_end   = defined $transcript->coding_region_end   ? $transcript->coding_region_end   : -1e6;
# /EG 
      my $composite2 = $self->Composite({ y => $y, height => $h });
            
      if ($transcript->translation) {
        $self->join_tag($composite2, $_->[0], 0.5, 0.5, $_->[1], 'line', $join_z) for @{$tags{$transcript->translation->stable_id}||[]};
      }
      
      if ($transcript_stable_id eq $tsid) {
        $self->join_tag($composite2, $_, 0.5, 0.5, $alt_alleles_col, 'line', $join_z) for @gene_tags;
        
        if (@gene_tags) {
          $self->{'legend'}{'gene_legend'}{'joins'}{'priority'} ||= 1000;
          $self->{'legend'}{'gene_legend'}{'joins'}{'legend'}{'Alternative alleles'} = $alt_alleles_col;
        }
      }
# EG: render multiple translations
      my %composites;#one for each translation
      
      for (my $i = 0; $i < @exons; $i++) {
        my $exon = $exons[$i][0];
        
        next unless defined $exon; # Skip this exon if it is not defined (can happen w/ genscans) 
        
        my $next_exon = ($i < $#exons) ? $exons[$i+1][0] : undef; # First draw the exon
        
        last if $exon->start > $length; # We are finished if this exon starts outside the slice
        
        my ($box_start, $box_end);
        
        # only draw this exon if is inside the slice
        if ($exon->end > -$addition) {
          # calculate exon region within boundaries of slice
          if(($start_point>$end_point) && ($gene->slice->end == $end_point)  && ($gene->slice->start != $start_point)) {
             $addition = $reg_end - $start_point + 1;
          } elsif ($gene->{_draw_translated}) {
             $addition = $reg_end + $start_point + 1;
          } else {           
             $addition = 0;
          }
          
          my $min_start = -$addition + 1;
          
          $box_start = $exon->start;
          $box_start = $min_start if $box_start < $min_start;
          $box_end = $exon->end;
          $box_end = $length if $box_end > $length;
          # The start of the transcript is before the start of the coding
          # region OR the end of the transcript is after the end of the
          # coding regions.  Non coding portions of exons, are drawn as
          # non-filled rectangles
          # Draw a non-filled rectangle around the entire exon
    
          if ($box_start < $coding_start || $box_end > $coding_end) {
            $composite2->push($self->Rect({
              x            => $box_start + $addition - 1,
              y            => $y + $non_coding_start,
              width        => $box_end - $box_start  + 1,
              height       => $non_coding_height,
              bordercolour => $colour,
              absolutey    => 1
             }));
           }
           
           # Calculate and draw the coding region of the exon
           my $filled_start = $box_start < $coding_start ? $coding_start : $box_start;
           my $filled_end   = $box_end > $coding_end ? $coding_end : $box_end;
                      
           # only draw the coding region if there is such a region
           if ($filled_start <= $filled_end ) {
              # Draw a filled rectangle in the coding region of the exon
              $composite2->push($self->Rect({
                x         => $filled_start + $addition - 1,
                y         => $y,
                width     => $filled_end - $filled_start + 1,
                height    => $h/$numTranslations,
                colour    => $colour,
                absolutey => 1
              }));
          }
          my $translationIndex=1;
          foreach my $alt_translation (@alt_translations){
            my $t_coding_start=$alt_translation->genomic_start;
            my $t_coding_end=$alt_translation->genomic_end;
            # Calculate and draw the coding region of the exon
            my $t_filled_start = $box_start < $t_coding_start ? $t_coding_start : $box_start;
            my $t_filled_end   = $box_end > $t_coding_end     ? $t_coding_end   : $box_end;
            # only draw the coding region if there is such a region
            # Draw a filled rectangle in the coding region of the exon
            if ($t_filled_start <= $t_filled_end) {
              $composites{$alt_translation->stable_id} = $self->Composite({ y => $y, height => $h }) unless defined $composites{$alt_translation->stable_id};
              my $_y= (int(10 * ($y + $translationIndex * $h/$numTranslations)))/10;
              my $_h= (int(10 * ($h/$numTranslations)))/10;
              $composites{$alt_translation->stable_id}->push(
                $self->Rect({
                 x         => abs($t_filled_start + $addition - 1),
                 width     => abs($t_filled_end - $t_filled_start + 1),
                 y         => $_y,
                 height    => $_h,
                 colour => $colour,
                 bordercolour => 'black',
                 absolutey => 1,
                 absolutex => 0
                 }
                )
              );
            }
            $translationIndex++;
          }
        }
        
        # we are finished if there is no other exon defined
        last unless defined $next_exon;
        
        next if $next_exon->dbID eq $exon->dbID;
        
        my $intron_start = $exon->end + 1; # calculate the start and end of this intron
        my $intron_end   = $next_exon->start - 1;
        
        next if $intron_end < 0;         # grab the next exon if this intron is before the slice
        last if $intron_start > $length; # we are done if this intron is after the slice

        if(($start_point>$end_point) && ($gene->slice->end == $end_point) && ($gene->slice->start != $start_point)) {
            $addition = $reg_end - $start_point + 1;
          #if ($exon->slice->is_circular) {
          # $addition = 0;
          #}
        } else {
            $addition = 0;
        }
        
        # calculate intron region within slice boundaries
        $box_start = $intron_start < 1 ? 1 : $intron_start;
        $box_end   = $intron_end > $length ? $length : $intron_end;
        
        my $intron;
        
        if ($box_start == $intron_start && $box_end == $intron_end) {
          # draw an wholly in slice intron
          $composite2->push($self->Intron({
            x         => $box_start + $addition - 1,
            y         => $y,
            width     => $box_end - $box_start + 1,
            height    => $h,
            colour    => $colour,
            absolutey => 1,
            strand    => $strand
          }));
        } else { 
          # else draw a "not in slice" intron
          $composite2->push($self->Line({
            x         => $box_start + $addition - 1 ,
            y         => $y + int($h/2),
            width     => $box_end - $box_start + 1,
            height    => 0,
            absolutey => 1,
            colour    => $colour,
            dotted    => 1
          }));
        }
      }
      foreach my $alt_translation (@alt_translations) {
        $composite2->push($composites{$alt_translation->stable_id});
      }
      $composite->push($composite2);
# /EG: render multiple translations
      
      my $bump_height = 1.5 * $h;
      
      if ($show_labels ne 'off' && $labels) {
        if (my $label = $self->feature_label($gene, $transcript)) {
          my @lines = split "\n", $label;
          
          for (my $i = 0; $i < @lines; $i++) {
            my $line = "$lines[$i] ";
            my $w = ($self->get_text_width(0, $line, '', 'ptsize' => $fontsize, 'font' => $fontname))[2];
            
            $composite->push($self->Text({
              x         => $composite->x,
              y         => $y + $h + $i*($th+1),
              height    => $th,
              width     => $w / $pix_per_bp,
              font      => $fontname,
              ptsize    => $fontsize,
              halign    => 'left', 
              colour    => $colour,
              text      => $line,
              absolutey => 1
            }));
            
            $bump_height += $th + 1;
          }
        }
      }

      # bump
      my $bump_start = int($composite->x * $pix_per_bp);
      my $bump_end = $bump_start + int($composite->width * $pix_per_bp) + 1;
      my $row = $self->bump_row($bump_start, $bump_end);
      
      # shift the composite container by however much we're bumped
      $composite->y($composite->y - $strand * $bump_height * $row);
      $composite->colour($highlights->{$transcript_stable_id}) if $config->get_option('opt_highlight_feature') != 0 && $highlights->{$transcript_stable_id} && !defined $target;
      $self->push($composite);
    }
  }
  foreach my $operon (@operons_to_draw) {
    my $operon_strand = $operon->strand;
    my $operon_stable_id = $operon->can('stable_id') ? $operon->stable_id : undef;
    next if $operon_strand != $strand && $strand_flag eq 'b'; # skip features on wrong strand
    next if $target_gene && $operon_stable_id ne $target_gene;
    my @sorted_transcripts = map $_->[1], sort { $b->[0] <=> $a->[0] } map [ $_->start * $operon_strand, $_ ],
      @{$operon->get_all_OperonTranscripts};

    foreach my $transcript (@sorted_transcripts) {
      my $colour_key = 'protein_coding';#$self->transcript_key($transcript, $gene);
      my $colour     = $self->my_colour($colour_key);
      my $transcript_stable_id = $transcript->stable_id;

      $transcript = $transcript->transfer($container) unless ($start_point > $end_point);
      if(($start_point>$end_point)) {
              $addition = $reg_end - $start_point + 1;
      } else {
              $addition = 0;
      }

      next if $transcript->start > $length || $transcript->end < 1;
      
      $used_colours{'operon transcript'} = $colour;
      my $composite = $self->Composite({
        y      => $y,
        height => $h,
       #title  => $self->title($transcript, $operon),
        href => $self->operon_href($operon,$transcript),
      });
      
      my @opgenes = sort {$a->start<=>$b->start} 
        map { $start_point < $end_point ? $_->transfer($container) : $_ }
        @{$transcript->get_all_Genes};
      if(0<@opgenes){
          $composite->push($self->_render_operon_genes(\@opgenes,0,{
            no_bump => 1,
            no_colour => 0,
            used_colours => \%used_colours
          }));
         #$composite->push($self->_render_operon_gene_labels(\@opgenes));
      }

      ###<<< draw the operon transcription empty box
      my ($fill_start, $fill_end);
      $fill_start = $transcript->start + $addition;
      $fill_start = 1 if $fill_start < 1 ;
      $fill_end = $transcript->end + $addition - 1;
      $fill_end = $length if $fill_end > $length;
      $composite->push($self->Rect({ # draw non-coding box
        x            => $fill_start ,
        y            => $y + $non_coding_start,
        width        => $fill_end - $fill_start + 1,
        height       => $non_coding_height,
        bordercolour => $colour,
        absolutey    => 1
      }));
      ###>>>
      $transcript_drawn = 1;        
      
      my $bump_height = 1.5 * $h;
 ##########################<operon labels>
      if ($show_labels ne 'off' && $labels) {
  ############################<gene labels>
        my $numrows=0;
        if($label_operon_genes && (0<scalar @opgenes)){
          $numrows=1;
          my $labels_in_row = {0=>{}};
          foreach my $gene (@opgenes){
           #$labels_in_row->{0}->{$gene->stable_id}=$gene;
           #next if($prev == $gene);
            my $gene_name = $gene->external_name;
            $gene->{op_label} = $gene_name;
            my $w = ($self->get_text_width(0, "$gene_name ", '', 'ptsize' => $fontsize, 'font' => $fontname))[2];
            $gene->{op_label_end}=$gene->start + $w/$pix_per_bp;
            $gene->{ww}=$w;
            $labels_in_row->{0}->{$gene->stable_id}=$gene;
          }
          for(my $r=0;$r<$numrows;$r++){
            my $overlaps_found=0;
            my @row_of_genes = sort {$a->start <=> $b->start} values %{$labels_in_row->{$r}};
            my $prev;
            foreach my $gene (@row_of_genes){
              if($prev && ($gene->start <= $prev->{op_label_end})){
                $overlaps_found+=1;
                $labels_in_row->{$r+1}->{$gene->stable_id}=$gene;
                delete $labels_in_row->{$r}->{$gene->stable_id};
                ##do not increment $prev
              }
              else{
                if($gene->stable_id eq $selected_gene){
                  $composite->push($self->Rect({
                    x         => $gene->start,
                    y         => $y + $h + $r*($th+1)+1,
                    height    => $th,
                    width     => $gene->length,
                    colour    => 'highlight2',
                    absolutey => 1
                  }));
                }
                $composite->push($self->Text({
                  x         => $gene->start,
                  y         => $y + $h + $r*($th+1),
                  height    => $th,
                  width     => $gene->{ww} / $pix_per_bp,
                  font      => $fontname,
                  ptsize    => $fontsize,
                  halign    => 'left', 
                  colour    => $colour,
                  text      => $gene->{op_label},
                  absolutey => 1
                }));
                $prev=$gene;
              }
            }
            if(0<$overlaps_found){$numrows+=1;}
            else{last;}
          }
        }
       $bump_height+= $numrows * ($th + 1);
  ############################</gene labels>
        if (my $text_label = $self->operon_text_label($operon, $transcript)) {
          my @lines = split "\n", $text_label; 
          $lines[0] = "< $lines[0]" if $strand < 1;
          $lines[0] = "$lines[0] >" if $strand >= 1;
          my $__Y=$numrows * ($th+1) + $y;
          
          for (my $i = 0; $i < @lines; $i++) {
            my $line = "$lines[$i] ";
            my $w = ($self->get_text_width(0, $line, '', 'ptsize' => $fontsize, 'font' => $fontname))[2];
            $composite->push($self->Text({
              x         => $composite->x,                          #$addition
              y         => $__Y + $h + ($i)*($th+1),
              height    => $th,
              width     => $w / $pix_per_bp,
              font      => $fontname,
              ptsize    => $fontsize,
              halign    => 'left', 
              colour    => $colour,
              text      => $line,
              absolutey => 1
            }));
            
            $bump_height += $th + 1;
          }
        }
      }
      
      if(1 < scalar @opgenes){
        my $prev;
        foreach my $gene (@opgenes){
          $gene = $gene->transfer($container);
          if($prev && ($gene->start - 1) <= $prev->end){
            $composite->push($self->Rect({
              x => $gene->start,
              y => $non_coding_start + 1,
              height => $non_coding_height - 2,
              width => $pix_per_bp,
              colour => 'beige',
              absolutey =>1
            })); 
          }
          $prev = $gene;
        }
      }
 ##########################</operon labels>    

      # bump
      my $bump_start = int($composite->x * $pix_per_bp);
      my $bump_end = $bump_start + int($composite->width * $pix_per_bp) + 1;
      my $row = $self->bump_row($bump_start, $bump_end);
      
      # shift the composite container by however much we're bumped
      $composite->y($composite->y - $strand * $bump_height * $row);
#     $composite->colour($highlight) if defined $highlight && !defined $target;
      $composite->colour('highlight1') if $selected_gene && grep(/^$selected_gene$/, map {$_->stable_id} @opgenes);
      $self->push($composite);
    }
  }
  

  if ($transcript_drawn) {
      my $type = $self->type;
      my %legend_old = @{$self->{'legend'}{'gene_legend'}{$type}{'legend'}||[]};
      $used_colours{$_} = $legend_old{$_} for keys %legend_old;
      my @legend = %used_colours;
      $self->{'legend'}{'gene_legend'}->{$type} = {
      priority => $self->_pos,
      legend   => \@legend
      };
  } elsif ($config->get_option('opt_empty_tracks') != 0) {
      $self->no_track_on_strand;
  }

}

1;

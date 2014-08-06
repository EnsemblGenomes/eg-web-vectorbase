=head1 LICENSE

Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Component;

use strict;

sub transcript_table {
  my $self        = shift;
  my $hub         = $self->hub;
  my $object      = $self->object;
  my $species     = $hub->species;
  my $table       = $self->new_twocol;
  my $html        = '';
  my $page_type   = ref($self) =~ /::Gene\b/ ? 'gene' : 'transcript';
  my $description = $object->gene_description;
     $description = '' if $description eq 'No description';

  if ($description) {
    my ($edb, $acc);
    
    if ($object->get_db eq 'vega') {
      $edb = 'Vega';
      $acc = $object->Obj->stable_id;
      $description .= sprintf ' <span class="small">%s</span>', $hub->get_ExtURL_link("Source: $edb", $edb . '_' . lc $page_type, $acc);
    } else {
      $description =~ s/EC\s+([-*\d]+\.[-*\d]+\.[-*\d]+\.[-*\d]+)/$self->EC_URL($1)/e;
      $description =~ s/\[\w+:([-\w\/\_]+)\;\w+:([\w\.]+)\]//g;
      ($edb, $acc) = ($1, $2);

      my $l1   =  $hub->get_ExtURL($edb, $acc);
      $l1      =~ s/\&amp\;/\&/g;
      my $t1   = "Source: $edb $acc";
      my $link = $l1 ? qq(<a href="$l1">$t1</a>) : $t1;

      $description .= qq( <span class="small">@{[ $link ]}</span>) if $acc && $acc ne 'content';
    }

    $table->add_row('Description', $description);
  }
  
  my $seq_region_name  = $object->seq_region_name;
  my $seq_region_start = $object->seq_region_start;
  my $seq_region_end   = $object->seq_region_end;

  my $location_html = sprintf(
    '<a href="%s" class="constant">%s: %s-%s</a> %s.',
    $hub->url({
      type   => 'Location',
      action => 'View',
      r      => "$seq_region_name:$seq_region_start-$seq_region_end"
    }),
    $self->neat_sr_name($object->seq_region_type, $seq_region_name),
    $self->thousandify($seq_region_start),
    $self->thousandify($seq_region_end),
    $object->seq_region_strand < 0 ? ' reverse strand' : 'forward strand'
  );
  
  # alternative (Vega) coordinates
  if ($object->get_db eq 'vega') {
    my $alt_assemblies  = $hub->species_defs->ALTERNATIVE_ASSEMBLIES || [];
    my ($vega_assembly) = map { $_ =~ /VEGA/; $_ } @$alt_assemblies;
    
    # set dnadb to 'vega' so that the assembly mapping is retrieved from there
    my $reg        = 'Bio::EnsEMBL::Registry';
    my $orig_group = $reg->get_DNAAdaptor($species, 'vega')->group;
    
    $reg->add_DNAAdaptor($species, 'vega', $species, 'vega');

    my $alt_slices = $object->vega_projection($vega_assembly); # project feature slice onto Vega assembly
    
    # link to Vega if there is an ungapped mapping of whole gene
    if (scalar @$alt_slices == 1 && $alt_slices->[0]->length == $object->feature_length) {
      my $l = $alt_slices->[0]->seq_region_name . ':' . $alt_slices->[0]->start . '-' . $alt_slices->[0]->end;
      
      $location_html .= ' [<span class="small">This corresponds to ';
      $location_html .= sprintf(
        '<a href="%s" target="external" class="constant">%s-%s</a>',
        $hub->ExtURL->get_url('VEGA_CONTIGVIEW', $l),
        $self->thousandify($alt_slices->[0]->start),
        $self->thousandify($alt_slices->[0]->end)
      );
      
      $location_html .= " in $vega_assembly coordinates</span>]";
    } else {
      $location_html .= sprintf qq{ [<span class="small">There is no ungapped mapping of this %s onto the $vega_assembly assembly</span>]}, lc $object->type_name;
    }
    
    $reg->add_DNAAdaptor($species, 'vega', $species, $orig_group); # set dnadb back to the original group
  }

  $location_html = "<p>$location_html</p>";

  if ($page_type eq 'gene') {
    # Haplotype/PAR locations
    my $alt_locs = $object->get_alternative_locations;

    if (@$alt_locs) {
      $location_html .= '
        <p> This gene is mapped to the following HAP/PARs:</p>
        <ul>';
      
      foreach my $loc (@$alt_locs) {
        my ($altchr, $altstart, $altend, $altseqregion) = @$loc;
        
        $location_html .= sprintf('
          <li><a href="/%s/Location/View?l=%s:%s-%s" class="constant">%s : %s-%s</a></li>', 
          $species, $altchr, $altstart, $altend, $altchr,
          $self->thousandify($altstart),
          $self->thousandify($altend)
        );
      }
      
      $location_html .= '
        </ul>';
    }
  }

  $table->add_row('Location', $location_html);

  my $insdc_accession;
  $insdc_accession = $self->object->insdc_accession if $self->object->can('insdc_accession');
  $table->add_row('INSDC coordinates',$insdc_accession) if $insdc_accession;

  my $gene = $object->gene;
  
  my $gencode_desc = "The GENCODE Basic set includes all genes in the GENCODE gene set but only a subset of the transcripts.";

  if ($gene) {
    my $transcript  = $page_type eq 'transcript' ? $object->stable_id : $hub->param('t');
    my $transcripts = $gene->get_all_Transcripts;
    my $count       = @$transcripts;
    my $plural      = 'transcripts';
    my $splices     = 'splice variants';
    my $action      = $hub->action;
    my %biotype_rows;

    my $trans_attribs = {};
    my $trans_gencode = {};

    foreach my $trans (@$transcripts) {
      foreach my $attrib_type (qw(CDS_start_NF CDS_end_NF gencode_basic)) {
        (my $attrib) = @{$trans->get_all_Attributes($attrib_type)};
        if($attrib_type eq 'gencode_basic') {
            if ($attrib && $attrib->value) {
              $trans_gencode->{$trans->stable_id}{$attrib_type} = $attrib->value;
            }
        } else {
          $trans_attribs->{$trans->stable_id}{$attrib_type} = $attrib->value if ($attrib && $attrib->value);
        }
      }
    }
    my %url_params = (
      type   => 'Transcript',
      action => $page_type eq 'gene' || $action eq 'ProteinSummary' ? 'Summary' : $action
    );
    
    if ($count == 1) { 
      $plural =~ s/s$//;
      $splices =~ s/s$//;
    }
    
    my $gene_html = "This gene has $count $plural ($splices)";
    
    if ($page_type eq 'transcript') {
      my $gene_id  = $gene->stable_id;
      my $gene_url = $hub->url({
        type   => 'Gene',
        action => 'Summary',
        g      => $gene_id
      });
      $gene_html = qq{This transcript is a product of gene <a href="$gene_url">$gene_id</a><br /><br />$gene_html};
    }
    
    my $show    = $hub->get_cookie_value('toggle_transcripts_table') eq 'open';
    my @columns = (
       { key => 'name',       sort => 'string',  title => 'Name'          },
       { key => 'transcript', sort => 'html',    title => 'Transcript ID' },
       { key => 'bp_length',  sort => 'numeric', title => 'Length (bp)'   },
       { key => 'protein',    sort => 'html',    title => 'Protein ID'    },
       { key => 'aa_length',  sort => 'numeric', title => 'Length (aa)'   },
       { key => 'biotype',    sort => 'html',    title => 'Biotype'       },
    );

    push @columns, { key => 'cds_tag', sort => 'html', title => 'CDS incomplete' } if %$trans_attribs;
## VB VB-2944    
    push @columns, { key => 'ccds', sort => 'html', title => 'CCDS' } if $species =~ /^Homo_sapiens|Mus_musculus/;
##    
    push @columns, { key => 'gencode_set', sort => 'html', title => 'GENCODE basic' } if %$trans_gencode;
    
    my @rows;
    
    foreach (map { $_->[2] } sort { $a->[0] cmp $b->[0] || $a->[1] cmp $b->[1] } map { [ $_->external_name, $_->stable_id, $_ ] } @$transcripts) {
      my $transcript_length = $_->length;
      my $tsi               = $_->stable_id;
      my $protein           = 'No protein product';
      my $protein_length    = '-';
      my $ccds              = '-';
      my $cds_tag           = '-';
      my $gencode_set       = '-';
      my $url               = $hub->url({ %url_params, t => $tsi });
      
      if ($_->translation) {
        $protein = sprintf(
          '<a href="%s">%s</a>',
          $hub->url({
            type   => 'Transcript',
            action => 'ProteinSummary',
            t      => $tsi
          }),
          $_->translation->stable_id
        );
        
        $protein_length = $_->translation->length;
      }
      
      if (my @CCDS = grep { $_->dbname eq 'CCDS' } @{$_->get_all_DBLinks}) {
        my %T = map { $_->primary_id => 1 } @CCDS;
        @CCDS = sort keys %T;
        $ccds = join ', ', map $hub->get_ExtURL_link($_, 'CCDS', $_), @CCDS;
      }
      if ($trans_attribs->{$tsi}) {
        if ($trans_attribs->{$tsi}{'CDS_start_NF'}) {
          if ($trans_attribs->{$tsi}{'CDS_end_NF'}) {
            $cds_tag = "5' and 3'";
          }
          else {
            $cds_tag = "5'";
          }
        }
        elsif ($trans_attribs->{$tsi}{'CDS_end_NF'}) {
         $cds_tag = "3'";
        }
      }

      if ($trans_gencode->{$tsi}) {
         if ($trans_gencode->{$tsi}{'gencode_basic'}) {
          $gencode_set = qq(<span class="glossary_mouseover">Y<span class="floating_popup">$gencode_desc</span></span>);
        }
       }
      (my $biotype = $_->biotype) =~ s/_/ /g;

      my $row = {
        name       => { value => $_->display_xref ? $_->display_xref->display_id : 'Novel', class => 'bold' },
        transcript => sprintf('<a href="%s">%s</a>', $url, $tsi),
        bp_length  => $transcript_length,
        protein    => $protein,
        aa_length  => $protein_length,
        biotype    => $self->glossary_mouseover(ucfirst $biotype),
        ccds       => $ccds,
        has_ccds   => $ccds eq '-' ? 0 : 1,
        cds_tag    => $cds_tag,
        gencode_set=> $gencode_set,
        options    => { class => $count == 1 || $tsi eq $transcript ? 'active' : '' }
      };
      
      $biotype = '.' if $biotype eq 'protein coding';
      $biotype_rows{$biotype} = [] unless exists $biotype_rows{$biotype};
      push @{$biotype_rows{$biotype}}, $row;
    }

    ## Additionally, sort by CCDS status and length
    while (my ($k,$v) = each (%biotype_rows)) {
      my @subsorted = sort {$b->{'has_ccds'} cmp $a->{'has_ccds'}
                            || $b->{'bp_length'} <=> $a->{'bp_length'}} @$v;
      $biotype_rows{$k} = \@subsorted;
    }

    # Add rows to transcript table
    push @rows, @{$biotype_rows{$_}} for sort keys %biotype_rows; 

    $table->add_row(
      $page_type eq 'gene' ? 'Transcripts' : 'Gene',
      $gene_html . sprintf(
        ' <a rel="transcripts_table" class="button toggle no_img set_cookie %s" href="#" title="Click to toggle the transcript table">
          <span class="closed">Show transcript table</span><span class="open">Hide transcript table</span>
        </a>',
        $show ? 'open' : 'closed'
      )
    );

    my $table_2 = $self->new_table(\@columns, \@rows, {
      data_table        => 1,
      data_table_config => { asStripClasses => [ '', '' ], oSearch => { sSearch => '', bRegex => 'false', bSmart => 'false' } },
      toggleable        => 1,
      class             => 'fixed_width' . ($show ? '' : ' hide'),
      id                => 'transcripts_table',
      exportable        => 0
    });

    $html = $table->render.$table_2->render;

  } else {
    $html = $table->render;
  }
  
  return qq{<div class="summary_panel">$html</div>};
}

1;

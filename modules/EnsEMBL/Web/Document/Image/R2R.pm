=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Document::Image::R2R;

use strict;

use EnsEMBL::Web::File::Dynamic;

sub _create_svg {
    my ($self, $aln_file, $peptide_id, $model_name, $with_consensus_structure) = @_;

    ## Path to the files we dumped earlier
    my $sub_dir = 'r2r_'.$self->hub->species;
    my $path    = $aln_file->base_read_path.'/'.$sub_dir;

    my $cons_filename  = $model_name.'.cons';
    ## For information about these options, check http://breaker.research.yale.edu/R2R/R2R-manual-1.0.3.pdf
    $self->_run_r2r_and_check("--GSC-weighted-consensus", $aln_file->absolute_read_path, $path, $cons_filename, "3 0.97 0.9 0.75 4 0.97 0.9 0.75 0.5 0.1");

    my $thumbnail = $model_name.'_thumbnail.svg';

    ## Note - r2r needs a file on disk, so we explicitly set the driver to IO
    my $th_file = EnsEMBL::Web::File::Dynamic->new(
                                                  hub             => $self->hub,
                                                  sub_dir         => $sub_dir,
                                                  name            => $thumbnail,
                                                  input_drivers   => ['IO'],
                                                  output_drivers  => ['IO'],
                                                  );

    unless ($th_file->exists) {

      my $th_meta = EnsEMBL::Web::File::Dynamic->new(
                                                  hub             => $self->hub,
                                                  sub_dir         => $sub_dir,
                                                  name            => $model_name.'_thumbnail.meta',
                                                  input_drivers   => ['IO'],
                                                  output_drivers  => ['IO'],
                                                  );
      unless ($th_meta->exists) {
        my $th_content = "$path/$cons_filename\tskeleton-with-pairbonds\n";
        $th_meta->write($th_content);
      }
## VB  Option to hide warnings in R2R 1.0.5 version 
## remove in E89 (assuming merge of https://github.com/Ensembl/ensembl-webcode/commit/4c85f1c9)
      $self->_run_r2r_and_check("--disable-usage-warning", $th_meta->absolute_read_path, $path, $thumbnail, "");
##
    }

    my $plot = $model_name.'.svg';

    ## Note - r2r needs a file on disk, so we explicitly set the driver to IO
    my $plot_file = EnsEMBL::Web::File::Dynamic->new(
                                                  hub             => $self->hub,
                                                  sub_dir         => $sub_dir,
                                                  name            => $plot,
                                                  input_drivers   => ['IO'],
                                                  output_drivers  => ['IO'],
                                                  );

    unless ($plot_file->exists) {

      my $plot_meta  = EnsEMBL::Web::File::Dynamic->new(
                                                      hub             => $self->hub,
                                                      sub_dir         => $sub_dir,
                                                      name            => $model_name.'.meta',
                                                      input_drivers   => ['IO'],
                                                      output_drivers  => ['IO'],
                                                      );


      unless ($plot_meta->exists) {
        my $content = $with_consensus_structure ? "$path/$cons_filename\n" : '';
        $content .= $aln_file->absolute_read_path."\toneseq\t$peptide_id\n";
        $plot_meta->write($content);
      }
## VB  Option to hide warnings in R2R 1.0.5 version 
## remove in E89 (assuming merge of https://github.com/Ensembl/ensembl-webcode/commit/4c85f1c9)
      $self->_run_r2r_and_check("--disable-usage-warning", $plot_meta->absolute_read_path, $path, $plot, "");
##       
    }

    return ($th_file->read_url, $plot_file->read_url);
}

1;


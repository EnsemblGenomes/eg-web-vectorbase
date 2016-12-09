=head1 LICENSE

Copyright [1999-2013] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

# $Id: ViewConfig.pm,v 1.132.2.1 2013-12-04 14:20:15 hr5 Exp $

package EnsEMBL::Web::ViewConfig;

use strict;

use EnsEMBL::Web::Document::Table;
use URI::Escape;

sub add_individual_selector {
  my ($self, $config) = @_;
  my $checkbox_name_template = $config->{checkbox_name_template} || '%s';
  my $checkbox_on_value      = $config->{checkbox_on_value} || 'on';  
  my $hub                    = $self->hub;
  
  # Selected individuals
  
  my $variations = $self->species_defs->databases->{'DATABASE_VARIATION'};
  my @strains    = (@{$variations->{'DEFAULT_STRAINS'}}, @{$variations->{'DISPLAY_STRAINS'}});
  my %seen;

  my $individual_table = EnsEMBL::Web::Document::Table->new([], [], { 
    data_table => 'no_col_toggle',
    exportable => 0,
  });
  
  $individual_table->code = 'individual_selector_individual';
  
  $individual_table->add_columns(   
    { key => 'individual',  title => 'Individual',  width => '20%' },  
    { key => 'description', title => 'Description', width => '70%' },  
    { key => 'checkbox',    title => '',            width => '2%'  },  
  );

  foreach my $i (sort @strains) {
    if (!$seen{$i}++) {
      
      my $checkbox = sprintf (
        qq{<input type="checkbox" name="%s" value="%s"%s />}, 
        sprintf( $checkbox_name_template, $i ),
        $checkbox_on_value,
        $self->get($i) eq $checkbox_on_value ? ' checked' : ''
      );
      
      $individual_table->add_row({ 
        individual => $i,
        description => $variations->{'DISPLAY_STRAIN_DESCRIPTION'}->{$i},
        checkbox   => $checkbox,
      });

    }
  }  

  # render
  
  my $referer = $hub->referer;
  my $redirect_url = join '/', $referer->{ENSEMBL_TYPE}, $referer->{ENSEMBL_ACTION}, $referer->{ENSEMBL_FUNCTION};
  
  $redirect_url =~ s/\/$//; # strip trailing slash
  my $ss_url = sprintf(
    '%s/#?g=%s&t=%s&s=%s&redirect_url=%s&tags=true:::has_genotypes', 
    $SiteDefs::VECTORBASE_SAMPLE_SEARCH_URL,
    $referer->{params}->{g}->[0] || '', 
    $referer->{params}->{t}->[0] || '',
    $hub->species, 
    uri_escape($redirect_url), 
  );

  $self->add_fieldset('Sample search')->append_child('div', { 
    inner_HTML => qq{
        <p>
          Try the new Sample Search (beta)
        </p>
        <p>
          <a class="button no_img " href="$ss_url" title="Click to launch Sample Search" target="_blank">Launch Sample Search</a>
        <p>
          <a href="$ss_url" target="_blank"><img src="/img/sample-search.png" alt="Sample search screenshot" title="Click to launch Sample Search" style="width:408px; height: 400px; border: #dddddd 1px solid" /></a>
        </p>          
    }
  });

  $self->add_fieldset('Selected samples')->append_child('div', { 
    inner_HTML => sprintf (
      qq{
        <p>Select the samples you wish to view from the list below. You can norrow the list by typing in the filter box. <b>Please note:</b> selecting large numbers of samples may cause this view to become unresponsive - the suggested maximum is 100.</p>            
        <div id="IndividualSelector" class="js_panel">
          <input type="hidden" class="subpanel_type" value="IndividualSelector" />
          <div style="text-align:right;margin-bottom:5px;"><a href="#" class="button">Select / deselect all</a></div>
          %s
        </div>
      },
      $individual_table->render,
    )
  });
}

1;

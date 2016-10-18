# $Id: PopulationImage.pm,v 1.3 2013-11-29 08:53:21 nl2 Exp $

package EnsEMBL::Web::ViewConfig::Transcript::PopulationImage;

use strict;

use EnsEMBL::Web::Constants;

sub form {
  my $self       = shift;
  my $variations = $self->species_defs->databases->{'DATABASE_VARIATION'};
  my %options    = EnsEMBL::Web::Constants::VARIATION_OPTIONS;
  my %validation = %{$options{'variation'}};
  my %class      = %{$options{'class'}};
  my %type       = %{$options{'type'}};

## VB - selected individuals and metadata
  $self->add_individual_selector({
    checkbox_name_template  => 'opt_pop_%s',
    checkbox_on_value       => 'on',
  });
##

  # Add source selection
  $self->add_fieldset('Variation source');
  
  foreach (sort keys %{$self->hub->table_info('variation', 'source')->{'counts'}}) {
    my $name = 'opt_' . lc $_;
    $name    =~ s/\s+/_/g;
    
    $self->add_form_element({
      type  => 'CheckBox', 
      label => $_,
      name  => $name,
      value => 'on',
      raw   => 1
    });
  }
  
  # Add class selection
  $self->add_fieldset('Variation class');
  
  foreach (keys %class) {
    $self->add_form_element({
      type  => 'CheckBox',
      label => $class{$_}[1],
      name  => lc $_,
      value => 'on',
      raw   => 1
    });
  }
  
  # Add type selection
  $self->add_fieldset('Consequence type');
  
  foreach (keys %type) {
    $self->add_form_element({
      type  => 'CheckBox',
      label => $type{$_}[1],
      name  => lc $_,
      value => 'on',
      raw   => 1
    });
  }

  # Add selection
  $self->add_fieldset('Consequence options');
  
  $self->add_form_element({
    type   => 'DropDown',
    select =>, 'select',
    label  => 'Type of consequences to display',
    name   => 'consequence_format',
    values => [
      { value => 'label',   caption => 'Sequence Ontology terms' },
      { value => 'display', caption => 'Old Ensembl terms'       },
    ]
  });  
  
  # Add context selection
  $self->add_fieldset('Intron Context');

  $self->add_form_element({
    type   => 'DropDown',
    select => 'select',
    name   => 'context',
    label  => 'Intron Context',
    values => [
      { value => '20',   caption => '20bp'         },
      { value => '50',   caption => '50bp'         },
      { value => '100',  caption => '100bp'        },
      { value => '200',  caption => '200bp'        },
      { value => '500',  caption => '500bp'        },
      { value => '1000', caption => '1000bp'       },
      { value => '2000', caption => '2000bp'       },
      { value => '5000', caption => '5000bp'       },
      { value => 'FULL', caption => 'Full Introns' }
    ]
  });

}

1;

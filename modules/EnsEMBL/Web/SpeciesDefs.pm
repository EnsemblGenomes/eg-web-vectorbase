package EnsEMBL::Web::SpeciesDefs;

use strict;
use warnings;
no warnings "uninitialized";

use previous qw (valid_species);

## VB
# for VB we have Drosophila Melanogaster configured for compara, 
# but we don't want it displayed anywhere
sub valid_species {
  my $self = shift;
  my @valid_species = $self->PREV::valid_species(@_);
  @valid_species = grep {$_ !~ /drosophila/i} @valid_species;
  return @valid_species;
}

sub assembly_lookup {
### Hash used to check if a given file or trackhub contains usable data
### @param old_assemblies - flag to indicate that older assemblies should be included
### @return lookup Hashref
###   The keys of this hashref are of the following two types:
###       - species_assembly    - used for attaching remote indexed files
###       - UCSC identifier     - used for checking trackhubs
  my ($self, $old_assemblies) = @_;
  my $lookup = {};
  foreach ($self->valid_species) {
    my $assembly = $self->get_config($_, 'ASSEMBLY_VERSION');

    ## REMOTE INDEXED FILES
    ## Unique keys, needed for attaching URL data to correct species
    ## even when assembly name is not unique
    $lookup->{$_.'_'.$assembly} = [$_, $assembly, 0];

    ## TRACKHUBS
    ## Add UCSC assembly name if available
    if ($self->get_config($_, 'UCSC_GOLDEN_PATH')) {
      $lookup->{$self->get_config($_, 'UCSC_GOLDEN_PATH')} = [$_, $assembly, 0];
    }
## VB-5588 make sure we always have assembly-only keys
##         this is a hack to ensure trackhubs can attach - needs revisiting    
   #else {
      ## Otherwise assembly-only keys for species with no UCSC id configured
      $lookup->{$assembly} = [$_, $assembly, 0];
    #}
##    
    if ($old_assemblies) {
      ## Include past UCSC assemblies
      if ($self->get_config($_, 'UCSC_ASSEMBLIES')) {
        my %ucsc = @{$self->get_config($_, 'UCSC_ASSEMBLIES')||[]};
        while (my($k, $v) = each(%ucsc)) {
          $lookup->{$k} = [$_, $v, 1];
        }
      }
    }
  }
  return $lookup;
}

1;

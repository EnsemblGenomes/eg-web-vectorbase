package EnsEMBL::Web::SpeciesDefs;

use strict;
use warnings;
no warnings "uninitialized";

sub valid_species {
  ### Filters the list of species to those configured in the object.
  ### If an empty list is passes, returns a list of all configured species
  ### Returns: array of configured species names
  
  my $self          = shift;
  my %test_species  = map { $_ => 1 } @_;
  my @valid_species = @{$self->{'_valid_species'} || []};
  
  if (!@valid_species) {
    foreach my $sp (@$SiteDefs::ENSEMBL_DATASETS) {
      my $config = $self->get_config($sp, 'DB_SPECIES');
      
      if ($config->[0]) {
        push @valid_species, @{$config};
      } else {
        warn "Species $sp is misconfigured: please check generation of packed file";
      }
    }
    
    $self->{'_valid_species'} = [ @valid_species ]; # cache the result
  }

  @valid_species = grep $test_species{$_}, @valid_species if %test_species; # Test arg list if required
  
  ## VB
  # for VB we have Drosophila Melanogaster configured for compara, 
  # but we don't want it displayed anywhere
  @valid_species = grep {$_ !~ /drosophila/i} @valid_species;
  ## /VB
    
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

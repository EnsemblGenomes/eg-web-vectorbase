package EnsEMBL::Web::SpeciesDefs;

use strict;
use warnings;
no warnings "uninitialized";

use previous qw(assembly_lookup);

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

## VB-5588 make sure we always have assembly-only keys
##         this is a hack to ensure trackhubs can attach - needs revisiting
sub assembly_lookup {
  my $self = shift
  my $lookup = $self->PREV::assembly_lookup(@_);
  foreach ($self->valid_species) {
    my $assembly = $self->get_config($_, 'ASSEMBLY_VERSION');
    $lookup->{$assembly} = [$_, $assembly, 0];
  }
  return $lookup;
}

1;

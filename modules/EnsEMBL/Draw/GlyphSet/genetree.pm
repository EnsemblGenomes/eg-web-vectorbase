package EnsEMBL::Draw::GlyphSet::genetree;
use strict;
use previous qw(_url);

# VB-5106 supress zmenu for Drosophila melanogaster by returning no url for the href 
sub _url {
  my $self = shift;
  return $_[0]->{species} =~ /drosophila/i ? undef : $self->PREV::_url(@_);
}

1;

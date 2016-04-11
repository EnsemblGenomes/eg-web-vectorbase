#
# EnsEMBL module for Bio::EnsEMBL::Funcgen::DBSQL::BaseFeatureAdaptor
#

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


=head1 CONTACT

  Please email comments or questions to the public Ensembl
  developers list at <http://lists.ensembl.org/mailman/listinfo/dev>.

  Questions may also be sent to the Ensembl help desk at
  <http://www.ensembl.org/Help/Contact>.


=head1 NAME

Bio::EnsEMBL::Funcgen::DBSQL::BaseFeatureAdaptor - Funcgen Feature Adaptor base class

=head1 SYNOPSIS

Abstract class - should not be instantiated.  Implementation of
abstract methods must be performed by subclasses.

=head1 DESCRIPTION

This is a base adaptor for Funcgen feature adaptors. This base class is simply a way
to redefine some methods to use with the Funcgen DB.

=cut

package Bio::EnsEMBL::Funcgen::DBSQL::BaseFeatureAdaptor;

use strict;
use warnings;

sub _get_by_Slice {
    my ($self, $slice, $orig_constraint, $query_type) = @_;
    
    # features can be scattered across multiple coordinate systems
    my @tables = $self->_tables;
    my ($table_name, $table_synonym) = @{ $tables[0] };
    my $mapper;
    my @feature_coord_systems;
    
    my $meta_values = $self->db->get_MetaContainer->list_value_by_key( $table_name."build.level");
    if ( @$meta_values and $slice->is_toplevel() ) {
        push @feature_coord_systems, $slice->coord_system();
    } else {
        @feature_coord_systems = @{ $self->db->get_MetaCoordContainer->fetch_all_CoordSystems_by_feature_type($table_name)};
    }
  
    my $assembly_mapper_adaptor = $self->db->get_AssemblyMapperAdaptor();
    my @pan_coord_features;
        
COORD_SYSTEM: foreach my $coord_system (@feature_coord_systems) {
        my @query_accumulator;
        # Build up a combination of query constraints that will quickly establish the result set
        my $constraint = $orig_constraint;


## VB hack - make the matching a little fuzzy because we have an assembly mismatch for 
##           some probe feature coord systems
#       if ( $coord_system->equals( $slice->coord_system ) ) {
        chop(my $slice_v = $coord_system->{version});
        chop(my $feat_v = $slice->coord_system->{version});
        if ($feat_cs->equals($slice_cs) || $feat_v eq $slice_v) {    
##   

            my $max_len = $self->_max_feature_length
                || $self->db->get_MetaCoordContainer
                    ->fetch_max_length_by_CoordSystem_feature_type( $coord_system,$table_name );
           
            # FUNCGEN        
            my @seq_region_ids = ($self->get_seq_region_id_by_Slice($slice, $coord_system));
            next if ! defined $seq_region_ids[0]; # Slice may not be present in funcgen DB

            #my $seq_region_id;        
            #if ( $slice->adaptor ) {
            #    $seq_region_id = $slice->adaptor->get_seq_region_id($slice);
            #} else {
            #    $seq_region_id = $self->db->get_SliceAdaptor->get_seq_region_id($slice);
            #}
            
            #my @seq_region_ids = ($seq_region_id);
            #while (1) {
            #    my $ext_seq_region_id = $self->get_seq_region_id_external($seq_region_id);       
            #    if ( $ext_seq_region_id == $seq_region_id ) { last }
            #    push( @seq_region_ids, $ext_seq_region_id );
            #    $seq_region_id = $ext_seq_region_id; # This is never used again
            #}
            
            $constraint .= " AND " if ($constraint);

            $constraint .= ${table_synonym}.".seq_region_id IN (". join( ',', @seq_region_ids ) . ") AND ";
            
            #faster query for 1bp slices where SNP data is not compressed
            if ( $self->start_equals_end && $slice->start == $slice->end ) {
                $constraint .= " AND ".$table_synonym.".seq_region_start = ".$slice->end .
                  " AND ".$table_synonym.".seq_region_end = ".$slice->start;
            
            } else {
                if ( !$slice->is_circular() ) {
                    # Deal with the default case of a non-circular chromosome.
                    $constraint .= $table_synonym.".seq_region_start <= ".$slice->end." AND "
                                   .$table_synonym.".seq_region_end >= ".$slice->start;
            
                    if ( $max_len ) {
                        my $min_start = $slice->start - $max_len;
                        $constraint .= " AND ".$table_synonym.".seq_region_start >= ".$min_start;
                    }
            
                } else {
                    # Deal with the case of a circular chromosome.
                    if ( $slice->start > $slice->end ) {
                        $constraint .= " ( ".$table_synonym.".seq_region_start >= ".$slice->start
                            . " OR ".$table_synonym.".seq_region_start <= ".$slice->end
                            . " OR ".$table_synonym.".seq_region_end >= ".$slice->start
                            . " OR ".$table_synonym.".seq_region_end <= ".$slice->end
                            . " OR ".$table_synonym.".seq_region_start > ".$table_synonym.".seq_region_end)";
                    } else {
                        $constraint .= " ((".$table_synonym.".seq_region_start <= ".$slice->end
                            . " AND ".$table_synonym.".seq_region_end >= ".$slice->start.") "
                            . "OR (".$table_synonym.".seq_region_start > ".$table_synonym.".seq_region_end"
                            . " AND (".$table_synonym.".seq_region_start <= ".$slice->end
                            . " OR ".$table_synonym.".seq_region_end >= ".$slice->start.")))";
                  }
              }
           }

           push @query_accumulator, [$constraint,undef,$slice]; # $mapper intentionally absent here.
           
        } else { 
=pod

#Table contains some feature on a CS that differs from the Slice CS
#can't do CS remapping yet as AssemblyMapper expects a core CS
#change AssemblyMapper?
#or do we just create a core CS just for the remap and convert back when done?

          #coordinate systems do not match
            $mapper = $assembly_mapper_adaptor->fetch_by_CoordSystems( $slice->coord_system(), $coord_system );
            next unless defined $mapper;

            # Get list of coordinates and corresponding internal ids for
            # regions the slice spans
            my @coords = $mapper->map( $slice->seq_region_name, $slice->start, $slice->end,
                                    $slice->strand, $slice->coord_system );

            @coords = grep { !$_->isa('Bio::EnsEMBL::Mapper::Gap') } @coords;

            next COORD_SYSTEM if ( !@coords );

            my @ids = map { $_->id() } @coords;
            #coords are now id rather than name
            
            if ( @coords > $MAX_SPLIT_QUERY_SEQ_REGIONS && ! $slice->isa('Bio::EnsEMBL::LRGSlice') 
                    && $slice->coord_system->name() ne 'lrg') {
                $constraint = $orig_constraint;
                my $id_str = join( ',', @ids );
                $constraint .= " AND " if ($constraint);
                $constraint .= $table_synonym.".seq_region_id IN ($id_str)";
                
                push @query_accumulator, [$constraint,$mapper,$slice];
            } else {
                my $max_len = (
                    $self->_max_feature_length()
                    || $self->db->get_MetaCoordContainer
                       ->fetch_max_length_by_CoordSystem_feature_type($coord_system, $table_name) 
                );

                my $length = @coords;
                for ( my $i = 0; $i < $length; $i++ ) {
                    $constraint = $orig_constraint;
                    $constraint .= " AND " if ($constraint);
                    $constraint .= $table_synonym.".seq_region_id = "
                        . $ids[$i] . " AND "
                        . $table_synonym.".seq_region_start <= "
                        . $coords[$i]->end() . " AND "
                        . $table_synonym.".seq_region_end >= "
                        . $coords[$i]->start();

                    if ($max_len) {
                        my $min_start = $coords[$i]->start() - $max_len;
                        $constraint .= " AND ".$table_synonym.".seq_region_start >= ".$min_start;
                    }
                    
                    push @query_accumulator, [$constraint,$mapper,$slice];
                } # end multi-query cycle
        } # end else
=cut
            
     } # end else (coord sytems not matching)
     
     #Record the bind params if we have to do multiple queries
     my $bind_params = $self->bind_param_generic_fetch();
     
     foreach my $query (@query_accumulator) {
         my ($local_constraint,$local_mapper,$local_slice) = @$query;
         $self->_bind_param_generic_fetch($bind_params);
         if ($query_type and $query_type eq 'count') {
           push @pan_coord_features, $self->generic_count($local_constraint);
         } 
         else {
             my $features = $self->generic_fetch( $local_constraint, $local_mapper, $local_slice );
             $features = $self->_remap( $features, $local_mapper, $local_slice );
             push @pan_coord_features, @$features;
         }
     }
     $mapper = undef;
    } # End foreach
    $self->{_bind_param_generic_fetch} = undef;
    return \@pan_coord_features;
}


1;



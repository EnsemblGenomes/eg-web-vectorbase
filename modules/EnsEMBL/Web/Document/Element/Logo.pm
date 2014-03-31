package EnsEMBL::Web::Document::Element::Logo;

use strict;

use base qw(EnsEMBL::Web::Document::Element);

sub image       :lvalue { $_[0]{'image'};       }
sub width       :lvalue { $_[0]{'width'};       }
sub height      :lvalue { $_[0]{'height'};      }
sub alt         :lvalue { $_[0]{'alt'};         }
sub href        :lvalue { $_[0]{'href'}         }
sub print_image :lvalue { $_[0]{'print_image'}; }

sub logo_img {
### a                                                                                                                                                                                                                                        
    my $self = shift;
  return sprintf(
    '<img src="%s%s" alt="%s" title="%s" class="print_hide" style="width:%spx;height:%spx" />',
    $self->img_url, $self->image, $self->alt, $self->alt, $self->width, $self->height
      );
}

sub logo_print {
### a                                                                                                                                                                                                                                        
    my $self = shift;
  return sprintf(
    '<img src="%s%s" alt="%s" title="%s" class="screen_hide_inline" style="width:%spx;height:%spx" />',
    $self->img_url, $self->print_image, $self->alt, $self->alt, $self->width, $self->height
      ) if ($self->print_image);
}

sub content {
    my $self = shift;
    my $url  = $self->href || $self->home_url;

    return sprintf '<a href="%s">%s</a>%s', $url, $self->logo_img, $self->logo_print;
}

sub init {
    my $self  = shift;
    my $style = $self->species_defs->ENSEMBL_STYLE;

    $self->image       = $style->{'SITE_LOGO'};
    $self->width       = $style->{'SITE_LOGO_WIDTH'};
    $self->height      = $style->{'SITE_LOGO_HEIGHT'};
    $self->alt         = $style->{'SITE_LOGO_ALT'};
    $self->href        = $style->{'SITE_LOGO_HREF'};
    $self->print_image = $style->{'PRINT_LOGO'};
}

1;


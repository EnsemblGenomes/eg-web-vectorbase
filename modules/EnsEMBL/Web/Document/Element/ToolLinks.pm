package EnsEMBL::Web::Document::Element::ToolLinks;

use strict;

sub content {
  my $self = shift;

  my @links;
  push @links, '<a class="constant" href="/about">About</a>';
  push @links, '<a class="constant" href="/navigation/downloads">Downloads</a>';
  push @links, '<a class="constant" href="/navigation/tools">Tools </a>';
  push @links, '<a class="constant" href="/navigation/data">Data</a>';
  push @links, '<a class="constant" href="/navigation/help">Help</a>';
  push @links, '<a class="constant" href="/navigation/community">Community</a>';
  push @links, '<a class="constant" href="/contact">Contact us</a>';
  push @links, '<a class="constant" href="/ensembl_tools.html">Browser Tools</a>';
  push @links, '<a class="constant" href="/info/website">Browser Help</a>';

  my $last  = pop @links;
  my $tools = join '', map "<li>$_</li>", @links;

  return qq{
    <ul class="tools">$tools<li class="last">$last</li></ul>
    <div class="more">
      <a href="#">More...</a>
    </div>
  };
}

1;

  

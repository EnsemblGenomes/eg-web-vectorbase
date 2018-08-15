#!/usr/bin/env perl

# script to generate thumbnails from a folder of larger images
# e.g. to create the 16px thumbnails from the 48px versions
#   perl utils/make_species_thumbnails.pl 16 htdocs/i/species/64 htdocs/i/species/16

use strict;
use warnings;
use 5.16.1;
use Getopt::Long;
use File::Slurp qw(read_dir);
use Imager;

my $size       = $ARGV[0] || die "Required: ARG 1 - thumbnail size in pixels";
my $source_dir = $ARGV[1] || die "Required: ARG 2 - source dir";
my $dest_dir   = $ARGV[2] || die "Required: ARG 3 - dest dir";

die "Source dir not found: $source_dir" unless -d $source_dir;
die "Dest dir not found: $dest_dir"     unless -d $dest_dir;

my @files = read_dir($source_dir);

foreach my $file (@files) {
  my $image = Imager->new();
  $image->read(file => "$source_dir/$file");
  save_thumbnail($image, "$dest_dir/$file", $size);
}

sub save_thumbnail {
  my ($image, $filename, $size) = @_;
  say "Writing thumbnail ($size x $size): $filename";
  my $thumb = $image->scale(xpixels => $size, ypixels => $size);
  if ($thumb) {
     $thumb = $thumb->crop(right => $size, bottom => $size);
     $thumb->write(file => $filename);
  } else {
    say "*** Failed to create image for $filename ***";
  }
}

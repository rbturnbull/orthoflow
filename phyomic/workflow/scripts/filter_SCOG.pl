#!/usr/bin/env perl
use strict;
use warnings;
use File::Copy;

my $outdir = "SC-OG";
mkdir($outdir);

my @files = <*.fa>;
for my $file (@files) {
    open FH,"$file";
    my $spp_encountered;
    my $scog = 1;
    while (my $line = <FH>) {
        if ($line =~ /^\>(.*?)\|/) {
            my $species = $1;
            if (defined $spp_encountered->{$species}) {
                $scog = 0;
            }
         $spp_encountered->{$species} = 1;
        }
    }
    close FH;
    if ($scog) {
        copy $file,$outdir."/".$file
    }
}
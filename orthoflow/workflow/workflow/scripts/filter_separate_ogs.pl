#!/usr/bin/env perl
use strict;
use warnings;
use File::Copy;

my $infile = shift @ARGV;
my $report = shift @ARGV;
my $minseq = shift @ARGV;
my $scogdir = shift @ARGV; 
my $mcogdir = shift @ARGV;

my $infile_absolute = $infile;
$infile =~ s/.*\///;

print "filter_separate_ogs.pl - filtering and separating OGs\n";

open REP,">".$report;

# reading $infile
unless(open FH,$infile_absolute) {die "ERROR -- failed to open $infile_absolute\n"}
my @a = <FH>;
close FH;

# counting sequences
my $str = join("",@a);
my $nrseqs = $str =~ tr/\>//;
if ($nrseqs < $minseq) {print REP "$infile - dropped for not meeting minimum sequence threshold ($minseq)\n"; exit;}

# counting taxa and repeat occurrences
my @matches = ( $str =~ /\>(.*?)\|/g );
my %seen = ();
my @uniq = grep { ! $seen{$_} ++ } @matches;
if (scalar @uniq < $minseq) {print REP "$infile - dropped for not meeting minimum species ($minseq)\n"; exit;}
if (scalar @uniq == scalar @matches) {
	print REP "$infile - single copy\n";
	unless (-e $scogdir) {mkdir $scogdir}
	copy($infile_absolute,$scogdir."/".$infile);
} else {
	print REP "$infile - multi copy\n";
	unless (-e $mcogdir) {mkdir $mcogdir}
	copy($infile_absolute,$mcogdir."/".$infile);
}

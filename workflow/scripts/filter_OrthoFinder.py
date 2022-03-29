#!/usr/bin/env python3
from argparse import ArgumentParser
import sys
import glob
import os
import subprocess
import re
import shutil

# parse command line
if len(sys.argv) == 1:
	sys.exit("FATAL ERROR: No command line arguments were passed to the program.\nFor help and options use the -h flag")
parser = ArgumentParser()
parser.add_argument('-i', '--input', help='path to OrthoFinder output', required=True)
parser.add_argument('-o', '--output',  help='output directory', required=True)
parser.add_argument('-m', '--min_seq',  help='minimum number of sequences', required=True)
args = parser.parse_args()
minseq = int(args.min_seq)

# prepare output directory
homedir = os.getcwd()
outdir = args.output
if os.path.isdir(outdir):
    sys.exit("Output directory already exists. Quitting. Remove the directory and try again.")
else:
    os.mkdir(outdir)

# filter OGs that have >= minseq sequences
OGdir = args.input+"/Orthogroup_Sequences"
GTdir = args.input+"/Gene_Trees"
os.chdir(OGdir)
fastaInputFiles = glob.glob('*.fa')
os.chdir(homedir)
counter = 0
p = re.compile("(OG\d+)\.fa")
for f in fastaInputFiles:
    counter = counter + 1
    print("file "+f)
    grepout = subprocess.check_output("grep -c '>' "+OGdir+"/"+f, shell=True)
    nseq = int(str(grepout, 'UTF-8'))
    if nseq >= minseq:
        print("  "+str(nseq)+" sequences - keeping")
        shutil.copyfile(OGdir+"/"+f, outdir+"/"+f)
        og = p.search(f).group(1)
        shutil.copyfile(GTdir+"/"+og+"_tree.txt", outdir+"/"+og+".nwk")
    else:
        print("  "+str(nseq)+" sequences - skipping")
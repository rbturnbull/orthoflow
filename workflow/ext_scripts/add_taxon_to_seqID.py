#!/usr/bin/env python3
from argparse import ArgumentParser
import sys

# parse command line
if len(sys.argv) == 1:
	print("FATAL ERROR: No command line arguments were passed to the program.\nFor help and options use the -h flag")
	exit()
parser = ArgumentParser()
parser.add_argument('-i', '--input', help='input file (fasta)', required=True)
parser.add_argument('-o', '--output', help='output file (fasta)', required=True)
parser.add_argument('-t', '--taxon', help='taxon name to add to seqIDs', required=True)
args = parser.parse_args()

# read input and create output on the fly
fin = open(args.input, 'r')
out = open(args.output, 'w')
for line in fin:
	if line.startswith('>'):
		line = line[:1]+args.taxon+'|'+line[1:]
	out.write(line)
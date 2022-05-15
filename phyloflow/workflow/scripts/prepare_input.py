#!/usr/bin/env python3
from argparse import ArgumentParser
import sys
import pandas as pd
import os

# parse command line
if len(sys.argv) == 1:
	sys.exit("FATAL ERROR: No command line arguments were passed to the program.\nFor help and options use the -h flag")
parser = ArgumentParser()
parser.add_argument('-i', '--input', help='input table (csv)', required=True)
args = parser.parse_args()
if not os.path.isfile(args.input):
	sys.exit("FATAL ERROR: "+args.input+" file not found")

# load input table
df = pd.read_csv(args.input)
print(df)

# add taxon names and translate sequences
for index, row in df.iterrows():
	infile = row["file"]
	print("processing "+infile)
	taxon = row['taxon_string']
	print(taxon)
	taxon = taxon.replace(" ","_")
	taxon = taxon.replace("|","_")
	print(" --> "+taxon)
	translation_table = row['translation_table']
	data_type = row['data_type']
	taxfile = infile+".tax.fa"
	tr_file = taxfile+".trans.fa"
	os.system("python3 ../add_taxon_to_seqID.py -i "+infile+" -o "+taxfile+" -t \""+taxon+"\"")
	os.system("conda run -n biokit biokit translate_sequence "+taxfile+" -o "+tr_file+" --translation_table "+str(translation_table))

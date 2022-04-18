import glob
import os
import sys
from Bio import SeqIO

# input files
cds_glob = '00_CDSs/*.tax.fa' # modify this to point to the input files that have the taxon_string prepended to seqIDs
orthosnap_glob = '02_OrthoSNAP/*.orthosnap.*' # modify this to point to the orthosnap output files

# first obtaining all sequence IDs present in the orthosnap output
error_encountered = False
target_file_dictionary = {}
ogfiles = glob.glob(orthosnap_glob) 
for ogfile in ogfiles:
	with open(ogfile) as f:
		for line in f:
			if line.startswith('>'):
				if line[1:] in target_file_dictionary:  # just making sure sequences don't occur across multiple OGs
					print("double occurrence "+line[1:])
					error_encountered = True
				target_file_dictionary[line[1:].rstrip()] = ogfile
orig_target_counter = len(target_file_dictionary.keys())
if error_encountered:  # exit with error code 1 if sequences occur in multiple OGs
	print("Terminating due to sequences re-occurring in multiple OGs")
	sys,exit(1)
print("dictionary complete, "+str(len(target_file_dictionary.keys())))
print("example entry: "+list(target_file_dictionary.keys())[0])

# removing output files if they exist, because code below depends on appending to the output files so we want to start from clean slate
for ogfile in ogfiles:
	if os.path.exists(ogfile+".cds.fa"):
		os.remove(ogfile+".cds.fa")

# loop through all sequences in CDS collection to find the targets and save those to files
counter = 0
for CDSfile in glob.glob(cds_glob): 
	for seq in SeqIO.parse(CDSfile,"fasta"):
		id = seq.id
		id = id.replace(":","_")   # added this here because it was also done in original sequence processing, I think this can be removed safely. It's just here because my prototyping dataset still had the ":" in there.
		if id in target_file_dictionary:
			counter = counter + 1
			ogfile = target_file_dictionary[id]
			with open(ogfile+".cds.fa",'a') as f:
				f.write(">"+id+"\n"+str(seq.seq)+"\n")
			target_file_dictionary.pop(id)
print("CDS retrieved: "+str(counter))

# exiting with error code 1 in case some sequences could not be retrieved
if counter != orig_target_counter:
	print("Some sequences are missing")
	print(sorted(target_file_dictionary.keys()))
	sys,exit(1)
else:
	print("Processing completed, appears to have run successfully")

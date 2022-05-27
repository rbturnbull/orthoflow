import os
import sys
from typing import List
from Bio import SeqIO

import typer


def matching_cds(
    cds_files: List[str] = typer.Option(..., help="The input CDS files that have the taxon_string prepended to seqIDs."),
    og_files: List[str] = typer.Option(..., help="The orthosnap output files."),
):
    """
    Locates the original CDSs so that the aligned (amino acid) sequences can be translated back.
    """
	# first obtaining all sequence IDs present in the orthosnap output
	error_encountered = False
	target_file_dictionary = {}
	for ogfile in og_files:
		with open(ogfile) as f:
			for line in f:
				if line.startswith('>'):
					if line[1:] in target_file_dictionary:  # just making sure sequences don't occur across multiple OGs
						print(f"double occurrence {line[1:]}")
						error_encountered = True
					target_file_dictionary[line[1:].rstrip()] = ogfile
	orig_target_counter = len(target_file_dictionary.keys())
	if error_encountered:  # exit with error code 1 if sequences occur in multiple OGs
		print("Terminating due to sequences re-occurring in multiple OGs")
		sys.exit(1)
	
	print(f"dictionary complete: {len(target_file_dictionary.keys())}")
	print(f"example entry: {list(target_file_dictionary.keys())[0]}")

	# removing output files if they exist, because code below depends on appending to the output files so we want to start from clean slate
	for ogfile in og_files:
		if os.path.exists(ogfile+".cds.fa"):
			os.remove(ogfile+".cds.fa")

	# loop through all sequences in CDS collection to find the targets and save those to files
	counter = 0
	for CDSfile in cds_files: 
		for seq in SeqIO.parse(CDSfile,"fasta"):
			id = seq.id
			
			# added this here because it was also done in original sequence processing, 
			# I think this can be removed safely. 
			# It's just here because my prototyping dataset still had the ":" in there.
			id = id.replace(":","_")   
			
			if id in target_file_dictionary:
				counter = counter + 1
				ogfile = target_file_dictionary[id]
				with open(ogfile+".cds.fa",'a') as f:
					f.write(f">{id}\n{seq.seq}\n")
				target_file_dictionary.pop(id)
	print(f"CDS retrieved: {counter}")

	# exiting with error code 1 in case some sequences could not be retrieved
	if counter != orig_target_counter:
		print("Some sequences are missing")
		print(sorted(target_file_dictionary.keys()))
		sys.exit(1)

	print("Processing completed successfully")


if __name__ == "__main__":
    typer.run(matching_cds)

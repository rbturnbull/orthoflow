#!/usr/bin/env python3
import sys
from pathlib import Path
from Bio import SeqIO

import typer


def matched_cds_path(ogfile:Path, output_dir:Path):
    output_dir.mkdir(parents=True, exist_ok=True)
    suffix_length = len(ogfile.suffix)
    return output_dir/f"{ogfile.name[:-suffix_length]}.cds.fa"

def matching_cds(
    cds_dir: Path = typer.Option(..., help="The directory of the input CDS files that have the taxon_string prepended to seqIDs."),
    og_dir: Path = typer.Option(..., help="The orthosnap output files directory."),
    output_dir: Path = typer.Option(..., help="The directory for the matched CDS files."),
):
    """
    Locates the original CDSs so that the aligned (amino acid) sequences can be translated back.
    """
    cds_files = list(cds_dir.glob("*.cds.fasta"))
    og_files = list(og_dir.glob("*.fa"))

    # first obtaining all sequence IDs present in the orthosnap output
    target_file_dictionary = {}
    for ogfile in og_files:
        with open(ogfile) as f:
            for line in f:
                if line.startswith('>'):
                    key = line[1:].rstrip()

                    # Ensure sequences don't occur across multiple OGs
                    if key in target_file_dictionary:  
                        raise ValueError(f"Terminating due to sequences re-occurring in multiple OGs: {key}")

                    target_file_dictionary[key] = ogfile
    
    orig_target_counter = len(target_file_dictionary.keys())
    
    print(f"dictionary complete: {len(target_file_dictionary.keys())}")
    print(f"example entry: {list(target_file_dictionary.keys())[0]}")
    
    # removing output files if they exist, because code below depends on appending to the output files so we want to start from clean slate
    for ogfile in og_files:
        output_file = matched_cds_path(ogfile, output_dir)
        if output_file.exists():
            output_file.unlink()

    # loop through all sequences in CDS collection to find the targets and save those to files
    counter = 0
    for cds_file in cds_files: 
        for seq in SeqIO.parse(cds_file,"fasta"):
            id = seq.id
            
            # added this here because it was also done in original sequence processing, 
            # I think this can be removed safely. 
            # It's just here because my prototyping dataset still had the ":" in there.
            id = id.replace(":","_")   
            
            if id in target_file_dictionary:
                counter = counter + 1
                ogfile = target_file_dictionary[id]
                output_file = matched_cds_path(ogfile, output_dir)
                with open(output_file,'a') as f:
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

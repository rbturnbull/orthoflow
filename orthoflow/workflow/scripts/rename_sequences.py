#!/usr/bin/env python3
import logging
from pathlib import Path
from typing import Optional
import typer
from Bio import SeqIO

logging.basicConfig(level="INFO")
logger = logging.getLogger("rename_sequences")



def rename_sequences(
    infile: Path = typer.Argument(..., file_okay=True, dir_okay=False, exists=True),
    outfile: Path = typer.Argument(..., file_okay=True, dir_okay=False, exists=False),
    data_type: str = typer.Option(...),
    taxon_string: str = typer.Option(..., help="The taxon string to be prepended to the description."),
    debug: Optional[bool] = typer.Option(False, "--debug", "-d"),
    warnings_dir: Path = None
):
    if debug:
        logger.setLevel("DEBUG")
    
    counter = 0

    # Get faulty sequences from warnings file
    warning_file = warnings_dir/"non_valid_objects.txt"
    wf_text = warning_file.read_text() if warning_file.exists() else ""

    with outfile.open("w") as fout:
        def write_seq(sequence, counter, gene = ""):
            seq_id = f"{taxon_string}|{infile.name}|{counter}"
            if gene:
                seq_id += f"|{gene}"

            print(f">{seq_id}", file=fout)
            print(sequence.upper(), file=fout)

        if data_type.lower() == "genbank":
            for seq in SeqIO.parse(infile, "genbank"):
                for feat in seq.features:
                    if feat.type == "CDS":
                        feat_seq = feat.extract(seq)
                        gene = "NA"
                        codon_start = 1
                        seq_str = feat_seq.seq
                        try:
                            gene = feat.qualifiers["gene"][0]
                        except:
                            logger.debug(f"CDS without gene name encountered in {infile} {counter}_{gene}")
                        try:
                            codon_start = int(feat.qualifiers["codon_start"][0])
                        except:
                            logger.debug(f"CDS without codon start position specification encountered in {infile} {counter}_{gene}")
                        if codon_start != 1:
                            seq_str = seq_str[codon_start-1:len(seq_str)]
                            logger.debug(f"CDS with codon start position different from 1 encountered in {infile} {counter}_{gene}; sequence has been trimmed at start")
                        modulo = len(seq_str) % 3
                        if modulo != 0:
                            seq_str = seq_str[0:len(seq_str)-modulo]
                            logger.debug(f"CDS of length not divisible by 3 encountered in {infile} {counter}_{gene}; sequence has been trimmed at end")
                        
                        write_seq(seq_str, counter=counter, gene=gene)
                        counter += 1
        else:
            # Assume that non-genbank files are Fasta format
            for seq in SeqIO.parse(infile, "fasta"):
                # Only add sequence of not present in warning file
                if not f"'{seq.id}' in file '{infile.name}'" in wf_text:
                    write_seq(seq.seq, counter=counter, gene=seq.id)
                counter += 1


    logger.debug(f"Extracted {counter} CDS from {infile} → {outfile}.")


if __name__ == "__main__":
    typer.run(rename_sequences)
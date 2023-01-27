import logging
from pathlib import Path
from typing import Optional

import typer
from Bio import SeqIO

logging.basicConfig(level="INFO")
logger = logging.getLogger("extract_cds")


def extract_cds(
    infile: Path = typer.Argument(..., file_okay=True, dir_okay=False, exists=True),
    outfile: Path = typer.Argument(..., file_okay=True, dir_okay=False, exists=False),
    data_type: str = typer.Argument(...),
    debug: Optional[bool] = typer.Option(False, "--debug", "-d"),
):
    if debug:
        logger.setLevel("DEBUG")
    
    counter = 0
    with outfile.open("w") as fout:
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
                            logger.debug(f"CDS without gene name encountered in {infile}")
                        try:
                            codon_start = int(feat.qualifiers["codon_start"][0])
                        except:
                            logger.debug(f"CDS without codon start position specification encountered in {infile}")
                        if codon_start != 1:
                            seq_str = seq_str[codon_start-1:len(seq_str)]
                            logger.debug(f"CDS with codon start position different from 1 encountered in {infile}; sequence has been trimmed at start")
                        modulo = len(seq_str) % 3
                        if modulo != 0:
                            seq_str = seq_str[0:len(seq_str)-modulo]
                            logger.debug(f"CDS of length not divisible by 3 encountered in {infile}; sequence has been trimmed at end")
                        
                        print(f">{infile.name}|{counter}|{gene}", file=fout)
                        print(seq_str, file=fout)
                        counter += 1
        else:
            # Assume that non-genbank files are Fasta format
            for seq in SeqIO.parse(infile, "fasta"):
                print(f">{infile.name}|{counter}", file=fout)
                print(seq.seq, file=fout)
                counter += 1

    logger.debug(f"Extracted {counter} CDS from {infile} → {outfile}.")

if __name__ == "__main__":
    typer.run(extract_cds)
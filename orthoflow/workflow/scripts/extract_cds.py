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
    debug: Optional[bool] = typer.Option(False, "--debug", "-d"),
):
    if debug:
        logger.setLevel("DEBUG")

    counter = 0
    with outfile.open("w") as fout:
        for seq in SeqIO.parse(infile, "genbank"):
            for feat in seq.features:
                if feat.type == "CDS":
                    feat_seq = feat.extract(seq)
                    print(">", seq.id, "|", feat.qualifiers["gene"][0], "\n", feat_seq.seq, sep="", file=fout)
                    counter += 1

    logger.debug(f"Extracted {counter} CDS from {infile} → {outfile}.")


if __name__ == "__main__":
    typer.run(extract_cds)

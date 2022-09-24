#!/usr/bin/env python3
import re
import shutil
from pathlib import Path

import typer


def main(
    og_dir: Path = typer.Argument(..., exists=True, file_okay=False, dir_okay=True),
    gt_dir: Path = typer.Argument(..., exists=True, file_okay=False, dir_okay=True),
    outdir: Path = typer.Argument(..., exists=False, file_okay=False, dir_okay=True),
    min_seqs: int = typer.Argument(...),
):

    # prepare output directory
    outdir.mkdir()

    # filter OGs that have >= min_seqs sequences
    fasta_input_files = list(og_dir.glob('*.fa'))
    pattern = re.compile(r"(OG\d+)\.fa")


    for fasta_file in fasta_input_files:
        fasta = fasta_file.read_text()
        fasta = fasta.replace(';', '_')
        nseq = fasta.count('>')
        if nseq >= min_seqs:
            (outdir / fasta_file.name).write_text(fasta)
            og = pattern.search(str(fasta_file)).group(1)
            shutil.copyfile(gt_dir / (og + "_tree.txt"), outdir / (og + ".nwk")) # can this be a softlink?


if __name__ == "__main__":
    typer.run(main)

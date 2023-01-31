#!/usr/bin/env python3
import re
from enum import Enum
from pathlib import Path
from collections import Counter
import typer

from joblib import Parallel, delayed
from rich.console import Console
console = Console()


OGClass = Enum('OGClass', ['SINGLE', 'MULTI', 'BELOW_MIN_SEQS', 'BELOW_MIN_TAXA'])

def classify_orthogroup(
    fasta_file: Path,
    min_seqs:int,
    min_taxa:int,
) -> OGClass:
    taxon_counter = Counter()

    pattern = re.compile(r"^>(.*?)\|.*$")
    with open(fasta_file, "r") as f:
        for line in f:
            match = pattern.match(line)
            if match:
                taxon = match.group(1).strip()
                taxon_counter.update([taxon])

    # Check to see the total number of sequences reaches the minimum
    seq_count = sum(taxon_counter.values())
    if seq_count < min_seqs:
        return OGClass.BELOW_MIN_SEQS

    # Check to see the total number of taxa reaches the minimum
    n_taxa = len(taxon_counter)
    if n_taxa < min_taxa:
        return OGClass.BELOW_MIN_TAXA

    # Get the number of most frequently occuring taxon
    # If it is just one then all taxa have only one copy and this is a single-copy OG
    # If it is higher than one then this is a multi-copy OG
    _ , top_count = taxon_counter.most_common(1)[0]
    if top_count == 1:
        return OGClass.SINGLE
    
    return OGClass.MULTI


def classify_all_orthogroups(
    directory: Path = typer.Argument(...,help="The directory of orthogroup sequences. Assumes all files have suffix .fa"),
    mcogs:Path = typer.Option(...,help="A text file to save a list of multi-copy orthogroups."),
    scogs:Path = typer.Option(...,help="A text file to save a list of single-copy orthogroups."),
    min_seqs:int = typer.Option(...,help="The minimum number of sequences in an orthogroup."),
    min_taxa:int = typer.Option(...,help="The minimum number of taxa in an orthogroup."),
    n_jobs:int = typer.Option(-1, help="The number of jobs to run in parallel. The default of -1 means that all CPUs are used."),
):  
    files = sorted(list(directory.glob("*.fa")))
    classifications = Parallel(n_jobs=n_jobs)(delayed(classify_orthogroup)(file, min_seqs, min_taxa) for file in files)

    with open(mcogs, "w") as mcogs_stream, open(scogs, "w") as scogs_stream:
        for file, classification in zip(files, classifications):
            if classification == OGClass.SINGLE:
                print(file, file=scogs_stream)
                style = "green"
            elif classification == OGClass.MULTI:
                print(file, file=mcogs_stream)
                style = "purple"
            elif classification == OGClass.BELOW_MIN_SEQS:
                style = "red"
            else:
                style = "dark_red"

            console.print(f"{file} -> {classification.name}", style=style)                


if __name__ == "__main__":
    typer.run(classify_all_orthogroups)

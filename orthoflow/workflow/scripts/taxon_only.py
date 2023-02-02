#!/usr/bin/env python3
from pathlib import Path
import re

import typer


def taxon_only(
    input_path: Path = typer.Argument(..., exists=True, dir_okay=False, help="The path to the input fasta alignment file."),
    output_path: Path = typer.Argument(..., file_okay=False, help="A path to where the output should be saved."),
    remove_duplicates: bool = typer.Option(True, help="Whether or not to remove secondary rows of taxa already in the alignment.")
):
    """
    Prepends the taxon name to the description line of a fasta file.
    """
    pattern = re.compile(r"^>(.*?)\|.*$")
    taxa = []
    write_line = True
    with open(input_path, "r") as input_file, open(output_path, "w") as output_file:
        for line in input_file:
            match = pattern.match(line)
            if match:
                taxon = match.group(1).strip()
                line = f">{taxon}\n"
                write_line = taxon not in taxa
                taxa.append(taxon)
            
            if write_line or not remove_duplicates:
                output_file.write(line)


if __name__ == "__main__":
    typer.run(taxon_only)

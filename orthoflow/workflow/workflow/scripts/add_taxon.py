#!/usr/bin/env python3
from collections import Counter
from pathlib import Path

import typer


def add_taxon(
    taxon: str = typer.Argument(..., help="The taxon name to be prepended to the description."),
    input_path: Path = typer.Argument(..., exists=True, dir_okay=False, help="The path to the input fasta file."),
    output_path: Path = typer.Argument(..., file_okay=False, help="A path to where the output should be saved."),
    delimiter: str = typer.Option(
        "|", help="A string to use to seperate the taxon name with the remainder of the description."
    ),
    unique_counter: bool = typer.Option(False, help="Include a unique CDS counter in description."),
):
    """
    Prepends the taxon name to the description line of a fasta file.
    """
    seq_counter = Counter()
    with open(input_path, "r") as input_file, open(output_path, "w") as output_file:
        for line in input_file:
            if line.startswith(">"):
                seq_id = line[1:]
                seq_counter_str = f"{seq_counter[seq_id]}{delimiter}" if unique_counter else ""
                line = f">{taxon}{delimiter}{seq_counter_str}{line[1:]}"
                seq_counter[seq_id] += 1
            output_file.write(line)


if __name__ == "__main__":
    typer.run(add_taxon)

from collections import Counter
from pathlib import Path
import re

import typer


def taxon_only(
    input_path: Path = typer.Argument(..., exists=True, dir_okay=False, help="The path to the input fasta alignment file."),
    output_path: Path = typer.Argument(..., file_okay=False, help="A path to where the output should be saved."),
):
    """
    Prepends the taxon name to the description line of a fasta file.
    """
    pattern = re.compile(r"^>(.*?)\|.*$")
    with open(input_path, "r") as input_file, open(output_path, "w") as output_file:
        for line in input_file:
            match = pattern.match(line)
            if match:
                line = f">{match.group(1).strip()}\n"
            output_file.write(line)


if __name__ == "__main__":
    typer.run(taxon_only)

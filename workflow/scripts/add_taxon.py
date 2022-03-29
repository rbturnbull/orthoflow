from pathlib import Path

import typer


def add_taxon(
    taxon: str,
    input_path: Path = typer.Argument(exists=True, dir_okay=False),
    output_path: Path = typer.Argument(file_okay=False),
    delimiter: str = "|",
):
    """
    Prepends the taxon name to the description line of a fasta file.

    Args:
        taxon (str): The taxon name to be prepended to the description.
        input_path (str): The path to the input fasta file.
        output_path (str): A path to where the output should be saved.
        delimiter (str): A string to use to seperate the taxon name with the remainder of the description. Default: '|'
    """
    with open(input_path, "r") as input_file, open(output_path, "w") as output_file:
        for line in input_file:
            if line.startswith(">"):
                line = f">{taxon}{delimiter}{line[1:]}"
            output_file.write(line)


if __name__ == "__main__":
    typer.run(add_taxon)

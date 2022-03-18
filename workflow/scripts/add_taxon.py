import typer

def add_taxon(
    taxon:str,
    input_path:str,
    output_path:str,
    delimiter:str = "|",
):
    """
    Prepends the taxon name to the description line of a fasta file.

    Args:
        taxon (str): The taxon name to be prepended to the description.
        input_path (str): The path to the input fasta file.
        output_path (str): A path to where the output should be saved.
        delimiter (str): A string to use to seperate the taxon name with the remainder of the description. Default: '|'
    """
    with open(input_path, 'w') as input_file, open(output_path, 'r') as output_file:
        for line in input_file:
            if line.startswith('>'):
                line = f">{taxon}{delimiter}{line[1:]}"
            output_file.write(line)

if __name__ == "__main__":
    if "snakemake" in locals():
        add_taxon(snakemake.input[0], snakemake.input[1], snakemake.output[0])
    else:
        typer.run(add_taxon)


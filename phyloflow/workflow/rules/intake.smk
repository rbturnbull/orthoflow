import pandas as pd
from pathlib import Path


def input_sources_row(source):
    """
    Reads a row in `input_sources.csv` based on the first part of the filename (before a '.').

    Returns:
        pd.Series: The row which corresponds to the file.
    """
    df = pd.read_csv("input_sources.csv")
    index = df['file'].apply(lambda x: x.split(".")[0]) == source
    if sum(index) != 1:
        raise Exception(f"Cannot find unique row with filename '{source}' in 'input_sources.csv'")
    return df[index]


def input_sources_item(source, column):
    """
    Reads a cell in `input_sources.csv` for a file and a column.
    """
    row = input_sources_row(source)
    val = row[column].item()

    # sanitize the string (remove spaces and other non-alpha-numeric characters)
    if isinstance(val, str):
        val = "".join([c if (c.isalnum() or c in "._-") else "_" for c in val])

    return val


rule extract_cds:
    """
    Extracts CDS features from GenBank files.

    Not used if input files already at in fasta format.

    :note: We use ``cp`` for existing fasta files instead of ``ln`` due to
           Snakemake having trouble identifying the creation of the symlinks.
    """
    output:
        "results/fasta/{source}.cds.fasta",
    input:
        input_sources="input_sources.csv",
        file=lambda wildcards: Path(input_sources_item(wildcards.source, 'file')).resolve(),
    conda:
        ENV_DIR / "extract_cds.yaml"
    params:
        is_genbank=lambda wildcards: input_sources_item(wildcards.source, 'data_type').lower()
        in ["genbank", "gb", "gbk"],
    shell:
        """
        if [ "{params.is_genbank}" = "True" ] ; then
            python {SCRIPT_DIR}/extract_cds.py --debug {input.file} {output}
        else
            cp {input.file} {output}
        fi
        """


rule add_taxon:
    """
    Prepends the taxon name to the description of each sequence in a fasta file.
    """
    output:
        "results/taxon-added/{source}.cds.fasta",
    input:
        input_sources="input_sources.csv",
        fasta="results/fasta/{source}.cds.fasta",
    conda:
        ENV_DIR / "typer.yaml"
    params:
        taxon=lambda wildcards: input_sources_item(wildcards.source, 'taxon_string'),
    shell:
        "python {SCRIPT_DIR}/add_taxon.py {params.taxon} {input.fasta} {output}"


rule translate:
    """
    Translates coding sequences to amino acid sequences using BioKIT.

    It relies on the `translation_table` column in `input_sources.csv`.
    It expects a number there which corresponds with the NCBI genetic codes:
    https://www.ncbi.nlm.nih.gov/Taxonomy/Utils/wprintgc.cgi?chapter=tgencodes

    BioKIT is found here: https://github.com/JLSteenwyk/BioKIT
    """
    output:
        "results/translated/{source}.cds.fasta",
    input:
        input_sources="input_sources.csv",
        fasta="results/taxon-added/{source}.cds.fasta",
    bibtex:
        "../bibs/biokit.bib"
    conda:
        ENV_DIR / "biokit.yaml"
    params:
        translation_table=lambda wildcards: input_sources_item(wildcards.source, 'translation_table'),
    shell:
        "biokit translate_sequence {input.fasta} --output {output} --translation_table {params.translation_table}"

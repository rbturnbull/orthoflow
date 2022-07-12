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
    Extracts CDS features from GenBank files or copies the CDS file.

    Not used if input files already at in fasta format.

    :note: We use ``cp`` for existing fasta files instead of ``ln`` due to
           Snakemake having trouble identifying the creation of the symlinks.
    """
    output:
        "results/intake/{source}.cds.fa",
    input:
        input_sources="input_sources.csv",
        file=lambda wildcards: Path(input_sources_item(wildcards.source, 'file')).resolve(),
    bibs:
        "../bibs/biopython.bib"
    conda:
        ENV_DIR / "biopython.yaml"
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

        # Sanitize the IDs
        sed '/^>/s/;/_/g;s/ //g' {output} > {output}.tmp && mv {output}.tmp {output}
        """

rule add_taxon:
    """
    Prepends the taxon name to the description of each sequence in a CDS file.
    """
    output:
        "results/intake/taxon-added/{source}.cds.fasta",
    input:
        rules.extract_cds.output,
    conda:
        ENV_DIR / "typer.yaml"
    params:
        taxon=lambda wildcards: input_sources_item(wildcards.source, 'taxon_string'),
    shell:
        "python {SCRIPT_DIR}/add_taxon.py --unique-counter {params.taxon} {input} {output}"


rule translate:
    """
    Translates coding sequences to amino acid sequences using BioKIT.

    It relies on the `translation_table` column in `input_sources.csv`.
    It expects a number there which corresponds with the NCBI genetic codes:
    https://www.ncbi.nlm.nih.gov/Taxonomy/Utils/wprintgc.cgi?chapter=tgencodes

    BioKIT is found here: https://github.com/JLSteenwyk/BioKIT
    """
    output:
        "results/intake/translated/{source}.protein.fa",
    input:
        rules.add_taxon.output
    bibs:
        "../bibs/biokit.bib"
    conda:
        ENV_DIR / "biokit.yaml"
    params:
        translation_table=lambda wildcards: input_sources_item(wildcards.source, 'translation_table'),
    shell:
        "biokit translate_sequence {input} --output {output} --translation_table {params.translation_table}"

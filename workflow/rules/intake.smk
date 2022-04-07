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
    return row[column].item()


rule gbseqextractor:
    """
    Extracts CDS features from GenBank files with gbseqextractor.

    Not used if input files already at in fasta format.
    gbseqextractor is found here: https://github.com/linzhi2013/gbseqextractor
    """
    output:
        "results/fasta/{source}.cds.fasta",
    input:
        input_sources="input_sources.csv",
        file=lambda wildcards: input_sources_item(wildcards.source, 'file'),
    conda:
        ENV_DIR / "intake.yaml"
    params:
        is_genbank=lambda wildcards: input_sources_item(wildcards.source, 'data_type').lower() in ["genbank", "gb"],
    shell:
        """
        if [ "{params.is_genbank}" = "True" ] ; then
            echo Using gbseqextractor to convert {input.file} to {output}
            gbseqextractor -f {input.file} -types CDS -prefix results/fasta/{wildcards.source}
        else
            echo File {input.file} not of type GenBank, creating softlink at {output}
            pwd
            echo ln -s {input.file} {output}
            ln -svr {input.file} {output}
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
        ENV_DIR / "intake.yaml"
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
    conda:
        ENV_DIR / "intake.yaml"
    params:
        translation_table=lambda wildcards: input_sources_item(wildcards.source, 'translation_table'),
    shell:
        "biokit translate_sequence {input.fasta} --output {output} --translation_table {params.translation_table}"

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

rule gbseqextractor:
    """
    Extracts CDS features from GenBank files with gbseqextractor.

    Not used if input files already at in fasta format.
    gbseqextractor is found here: https://github.com/linzhi2013/gbseqextractor
    """
    input:
        lambda wildcards: Path(".").glob(f"{wildcards.source}.*"),
    output:
        "results/fasta/{source}.cds.fasta",
    conda:
        ENV_DIR / "intake.yaml"
    params:
        outdir="results/fasta",
        input_fullpath=lambda wildcards, input: Path(input[0]).absolute(),
    shell:
        "cd {params.outdir} && gbseqextractor -f {params.input_fullpath} -types CDS -prefix {wildcards.source}"


rule add_taxon:
    """
    Prepends the taxon name to the description of each sequence in a fasta file.
    """
    input:
        "results/fasta/{source}.cds.fasta",
    output:
        "results/taxon-added/{source}.cds.fasta",
    conda:
        ENV_DIR / "intake.yaml"
    params:
        taxon=lambda w: input_sources_row(w.source)['taxon_string'].item(),
    shell:
        "python {SNAKE_DIR}/scripts/add_taxon.py {params} {input} {output}"


rule translate:
    """
    Translates coding sequences to amino acid sequences using BioKIT.

    It relies on the `translation_table` column in `input_sources.csv`.
    It expects a number there which corresponds with the NCBI genetic codes: 
    https://www.ncbi.nlm.nih.gov/Taxonomy/Utils/wprintgc.cgi?chapter=tgencodes
    
    BioKIT is found here: https://github.com/JLSteenwyk/BioKIT
    """
    input:
        "results/taxon-added/{source}.cds.fasta",
    output:
        "results/translated/{source}.cds.fasta",
    conda:
        ENV_DIR / "intake.yaml"
    params:
        translation_table=lambda w: input_sources_row(w.source)['translation_table'].item(),
    shell:
        "biokit translate_sequence {input} --output {output} --translation_table {params.translation_table}"

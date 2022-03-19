import pandas as pd
from pathlib import Path

def input_sources_row(fname):
    df = pd.read_csv("input_sources.csv")
    fname = fname.split('.')[0]
    index = df['file'].apply(lambda x: x.split(".")[0]) == fname
    if sum(index) != 1:
        raise Exception(f"Cannot find unique row with file '{fname}' in input_sources.csv")
    return df[index]

rule gbseqextractor:
    input:
        "{fname}.gb"
    output:
        "{fname}.cds.fasta"
    conda:
        ENV_DIR / "intake.yaml"
    shell:
        "gbseqextractor -f {input} -types CDS -prefix {wildcards.fname}"

rule add_taxon:
    input:
        csv="input_sources.csv",
        fasta="{fname}.fasta"
    output:
        "taxon-added/{fname}.fasta"
    conda:
        ENV_DIR / "intake.yaml"
    params:
        taxon=lambda w: input_sources_row(w.fname)['taxon_string'].item()
    script:
        "../scripts/add_taxon.py"

rule translate:
    input:
        "taxon-added/{fname}.fasta"
    output:
        "translated/{fname}.fasta"
    conda:
        ENV_DIR / "intake.yaml"
    shell:
        # should this have --translation_table <code>?
        "biokit translate_sequence {input} --output {output}"

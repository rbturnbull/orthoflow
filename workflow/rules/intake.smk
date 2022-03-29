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
        "{fname}.gb",
    output:
        "results/{fname}.cds.fasta",
    conda:
        "envs/intake.yaml"
    shell:
        "gbseqextractor -f {input} -types CDS -prefix {wildcards.fname}"


rule add_taxon:
    input:
        csv="input_sources.csv",
        fasta="{fname}.fasta",
    output:
        "results/taxon-added/{fname}.fasta",
    conda:
        "envs/intake.yaml"
    params:
        lambda w: input_sources_row(w.fname)['taxon_string'].item(),
    shell:
        "python scripts/add_taxon.py {params} {input.fasta} {output}"


checkpoint translate:
    input:
        "results/taxon-added/{fname}.fasta",
    output:
        "results/translated/{fname}.fasta",
    conda:
        "envs/intake.yaml"
    shell:
        # should this have --translation_table <code>?
        "biokit translate_sequence {input} --output {output}"

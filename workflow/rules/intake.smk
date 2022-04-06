import pandas as pd
from pathlib import Path


def input_sources_row(source):
    df = pd.read_csv(Path(config["data"]) / "input_sources.csv")
    index = df['file'].apply(lambda x: x.split(".")[0]) == source
    if sum(index) != 1:
        raise Exception(f"Cannot find unique row with file '{fname}' in input_sources.csv")
    return df[index]


rule gbseqextractor:
    input:
        lambda wildcards: Path(config["data"]).glob(f"{wildcards.source}.*"),
    output:
        "results/fasta/{source}.cds.fasta",
    conda:
        ENV_DIR / "intake.yaml"
    shell:
        "gbseqextractor -f {input} -types CDS -prefix {wildcards.source}"


rule add_taxon:
    input:
        "results/fasta/{source}.cds.fasta",
    output:
        "results/taxon-added/{source}.cds.fasta",
    conda:
        ENV_DIR / "intake.yaml"
    params:
        lambda w: input_sources_row(w.source)['taxon_string'].item(),
    shell:
        "python scripts/add_taxon.py {params} {input} {output}"


rule translate:
    input:
        "results/taxon-added/{source}.cds.fasta",
    output:
        "results/translated/{source}.cds.fasta",
    conda:
        ENV_DIR / "intake.yaml"
    shell:
        # should this have --translation_table <code>?
        "biokit translate_sequence {input} --output {output}"

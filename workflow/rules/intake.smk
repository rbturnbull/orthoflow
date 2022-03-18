
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

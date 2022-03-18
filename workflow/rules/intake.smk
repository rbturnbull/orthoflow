
rule gbseqextractor:
    input:
        multiext("{fname}.", "gb", "gbk", "txt")
    output:
        lambda wildcards: "{wildcards.fname}.cds.fasta"
    conda:
        ENV_DIR / "intake.yaml"
    run:
        for i, fname in zip(inputs,wildcards):
            shell("gbseqextractor -f {i} -types CDS -prefix results/{fname}")

rule add_taxon:
    input:
        "testing/input_sources.csv",
        "testing/{fname}.fasta"
    output:
        "testing/taxon-added/{fname}.fasta"
    conda:
        ENV_DIR / "intake.yaml"
    script:
        "scripts/add_taxon.py"

rule translate:
    input:
        "testing/taxon-added/{fname}.fasta"
    output:
        "testing/translated/{fname}.fasta"
    conda:
        ENV_DIR / "intake.yaml"
    shell:
        "biokit translate_sequence {input} --translation_table {code} --output {output}"

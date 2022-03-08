
rule gbconvert:
    input:
        DATA_DIR / "{i}.gb",
    output:
        RESULTS_DIR / "{i}.fasta"
    shell:
        "touch {output}"


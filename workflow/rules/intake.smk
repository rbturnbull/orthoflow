
rule gbseqextractor:
    input:
        "datasets/01_chloroplast_genomes/{accession}.gb"
    output:
        "results/{accession}.cds.fasta"
    conda:
        ENV_DIR / "gbseqextractor.yaml"
    shell:
        "gbseqextractor -f {input} -types CDS -prefix results/{wildcards.accession}"


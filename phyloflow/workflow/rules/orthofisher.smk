import pandas as pd

rule orthofisher_input_generation:
    """
    Runs `orthofisher <https://github.com/JLSteenwyk/orthofisher>`_ on input files of FASTA file and pHMM paths the intake rule.

    :config: orthofisher_hmmer_file
    """
    input:
        pd.read_csv("input_sources.csv")['file'].map(lambda f: f"results/translated/{f.split('.')[0]}.cds.fasta"),
    output:
        "results/orthofisher-input.tsv"
    log:
        LOG_DIR / "orthofisher_input_generation.txt",
    shell:
        """
        paste <(awk '{print $1}' {input})
        """


rule orthofisher:
    """
    Runs `orthofisher <https://github.com/JLSteenwyk/orthofisher>`_ on input files of FASTA file and pHMM paths the intake rule.

    :config: orthofisher_hmmer_file
    """
    input:
        "results/orthofisher-input.tsv"
    output:
        directory("results/orthologs"),
    conda:
        ENV_DIR / "orthofisher.yaml"
    log:
        LOG_DIR / "orthofisher.txt",
    bibs:
        "../bibs/orthofisher.nbib",
    params:
        hmms_file=config["orthofisher_hmmer_file"],
    shell:
        """
        orthofisher -m {params.hmms_file} -f {input} -o {output}
        """

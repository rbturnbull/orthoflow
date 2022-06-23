import pandas as pd

rule orthofisher_input_generation:
    """
    Runs `orthofisher <https://github.com/JLSteenwyk/orthofisher>`_ on input files of FASTA file and pHMM paths the intake rule.

    :config: orthofisher_hmmer_file
    """
    input:
        pd.read_csv("input_sources.csv")['file'].map(lambda f: f"results/translated/{f.split('.')[0]}.cds.fasta"),
    output:
        tsv="results/orthofisher-input.tsv",
        hmm="results/hmms.txt",
    params:
        hmm_files="\n".join(config["orthofisher_hmmer_files"]),
    log:
        LOG_DIR / "orthofisher_input_generation.txt",
    shell:
        """
        echo "{params.hmm_files}" > {output.hmm}
        echo {input} | tr " " "\n" > {output.tsv}
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
    shell:
        """
        orthofisher -m {params.hmms_file} -f {input} -o {output}
        """

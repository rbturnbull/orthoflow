import pandas as pd

rule orthofisher_input_generation:
    """
    Runs `orthofisher <https://github.com/JLSteenwyk/orthofisher>`_ on input files of FASTA file and pHMM paths the intake rule.

    :config: orthofisher_hmmer_files
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
    """
    input:
        tsv=rules.orthofisher_input_generation.output.tsv,
        hmm=rules.orthofisher_input_generation.output.hmm,
    output:
        directory("results/orthofisher"),
    conda:
        ENV_DIR / "orthofisher.yaml"
    log:
        LOG_DIR / "orthofisher.txt",
    bibs:
        "../bibs/orthofisher.nbib",
    shell:
        """
        orthofisher -m {input.hmm} -f {input.tsv} -o {output}
        """

rule orthofisher_filter:
    """
    Filters the output of orthofisher so that it only keeps the orthologs with a minimum number of sequences.
    """
    input:
        rules.orthofisher.output
    output:
        directory("results/orthologs"),
    params:
        min_seqs=config["ortholog_min_seqs"],
    shell:
        """
        mkdir {output}
        for i in $(ls {input}/scog/); do
            nseq=$(grep ">" {input}/scog/$i | wc -l)
            if [[ $nseq -ge {params.min_seqs} ]]; then
                cp {input}/scog/$i {output}/$i.fa
            fi
        done
        """

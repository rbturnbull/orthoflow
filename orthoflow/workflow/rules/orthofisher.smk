import pandas as pd

rule orthofisher_input_generation:
    """
    Runs `orthofisher <https://github.com/JLSteenwyk/orthofisher>`_ on input files of FASTA file and pHMM paths the intake rule.

    :config orthofisher_hmmer_files: list of hmmer files for orthofisher
    """
    input:
        input_csv['file'].map(lambda f: f"results/intake/translated/{f.split('.')[0]}.protein.fa"),
    output:
        tsv="results/orthofisher/input_protein_files.tsv",
        hmm="results/orthofisher/hmms.txt",
    params:
        hmm_files="\n".join(config["orthofisher_hmmer_files"]),
    log:
        LOG_DIR / "orthofisher_input_generation.txt",
    shell:
        """
        echo "{params.hmm_files}" > {output.hmm}
        echo {input} | tr " " "\n" > {output.tsv}
        """


checkpoint orthofisher:
    """
    Runs `orthofisher <https://github.com/JLSteenwyk/orthofisher>`_ on input files of FASTA file and pHMM paths the intake rule.
    """
    input:
        tsv=rules.orthofisher_input_generation.output.tsv,
        hmm=rules.orthofisher_input_generation.output.hmm,
    output:
        directory("results/orthofisher/output"),
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


def list_orthofisher_scogs(wildcards):
    checkpoint_output = checkpoints.orthofisher.get(**wildcards).output[0]
    scog = Path(checkpoint_output)/"scog"
    return list(scog.glob("*.hmm.orthofisher"))


checkpoint min_seq_filter_orthofisher:
    """
    List all the ortholog ids and puts them in a file.

    Only keeps the orthologs with a minimum number of sequences.
    It also removes suffixes added to the IDs by orthofisher.

    :config ortholog_min_seqs: Minimum number of sequences that needs to be in an alignment for it to proceed to phylogenetic analysis
    """
    input:
        list_orthofisher_scogs
    output:
        directory("results/orthofisher/min-seq-filtered"),
    params:
        min_seqs=config.get("ortholog_min_seqs", ORTHOLOG_MIN_SEQS_DEFAULT),
    shell:
        """
        mkdir -p {output}
        for i in {input}; do
            nseq=$(grep ">" $i | wc -l)

            if [[ $nseq -ge {params.min_seqs} ]]; then
                og=$(basename $i | sed 's/\..*//g')
                path={output}/$og.fa
                echo "Copying $i to $path and editing IDs"
                cat $i | cut -f1,2,3,4 -d'|' > $path
            fi
        done
        """
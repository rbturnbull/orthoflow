import pandas as pd


def hmmer_config_setup():
    hmm_files = []
    config_list = config.get("orthofisher_hmmer_files", None)
    if not config_list:
        default_hmm_dir = RESOURCES_DIR/"hmms"
        config_list = [default_hmm_dir]

    for item in config_list:
        item = Path(item)
        if not item.exists():
            print(f"HMM file {item} does not exist and is not used as an HMM profile.")
        elif item.is_dir():
            for file in item.glob("*.hmm"):
                hmm_files.append(file)
        else:
            hmm_files.append(item)

    return hmm_files


rule orthofisher_input_generation:
    """
    Runs `orthofisher <https://github.com/JLSteenwyk/orthofisher>`_ on input files of FASTA file and pHMM paths the intake rule.

    :config orthofisher_hmmer_files: list of hmmer files for orthofisher
    """
    input:
        protein_files
    output:
        tsv="results/orthofisher/input_protein_files.tsv",
        hmm="results/orthofisher/hmms.txt",
    params:
        hmm_list=hmmer_config_setup(),
    log:
        LOG_DIR / "orthofisher/orthofisher_input_generation.log",
    shell:
        """
        echo "Running orthofisher_input_generation" 2>&1 | tee {log}
        mkdir -p results/orthofisher 2>&1 | tee -a {log}
        echo HHMs: {params.hmm_list}
        for FILE in {params.hmm_list}; do
            echo $FILE
            if [ -s "$FILE" ]; then
                echo "$FILE" >> {output.hmm} 2>&1 | tee -a {log}
            fi
        done
        {{ echo {input} | tr " " "\n" > {output.tsv} ; }} 2>&1 | tee -a {log}
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
        LOG_DIR / "orthofisher/orthofisher.log",
    # bibs:
    #     "../bibs/orthofisher.nbib",
    shell:
        """
        orthofisher -m {input.hmm} -f {input.tsv} -o {output} 2>&1 | tee {log}
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
        min_seqs=max(3,config.get("ortholog_min_seqs", ORTHOLOG_MIN_SEQS_DEFAULT)),
    log:
        LOG_DIR / "orthofisher/min_seq_filter_orthofisher.log"
    shell:
        """
        mkdir -p {output} 2>&1 | tee {log}
        for i in {input}; do
            nseq=$(grep ">" $i | wc -l)

            if [[ $nseq -ge {params.min_seqs} ]]; then
                og=$(basename $i | sed 's/\..*//g')
                path={output}/$og.fa
                echo "Copying $i to $path and editing IDs" 2>&1 | tee -a {log}
                {{ cat $i | cut -f1,2,3,4 -d'|' > $path ; }} 2>&1 | tee -a {log}
            fi
        done
        """
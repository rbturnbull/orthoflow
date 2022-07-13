from pathlib import Path
from collections import namedtuple
import re


rule orthofinder:
    """
    Runs `OrthoFinder <https://github.com/davidemms/OrthoFinder>`_ on fasta files from the intake rule.
    """
    input:
        pd.read_csv("input_sources.csv")['file'].map(lambda f: f"results/intake/translated/{f.split('.')[0]}.protein.fa"),
    output:
        directory("results/orthofinder/output"),
    conda:
        ENV_DIR / "orthofinder.yaml"
    log:
        LOG_DIR / "orthofinder.txt",
    bibs:
        "../bibs/orthofinder.ris",
    params:
        input_dir=lambda wildcards, input: Path(input[0]).parent,
    threads: workflow.cores
    shell:
        """
        mkdir -p results/orthofinder
        orthofinder -f {params.input_dir} -t {threads} -n phyloflow -ot -M msa -X
        mv {params.input_dir}/OrthoFinder/Results_phyloflow/ {output}
        """

checkpoint split_scogs_and_multi_copy_ogs:
    """
    Takes the output of orthofinder and outputs the SCOGs.

    It is more liberal than orthofinder SCOGs.

    # TODO think about making this work per file

    :config: ortholog_min_seqs
    """
    input:
        rules.orthofinder.output,
    output:
        scogs=directory("results/orthofinder/scogs"),
        multi_copy_ogs=directory("results/orthofinder/multi_copy_ogs"),
    params:
        min_seqs=config.get("ortholog_min_seqs", ORTHOLOG_MIN_SEQS_DEFAULT),
    shell:
        """
        mkdir -p {output.multi_copy_ogs}
        mkdir -p {output.scogs}
        for i in $(ls {input}/Orthogroup_Sequences/); do
            echo $i
            taxa_and_counts=$(grep ">" {input}/Orthogroup_Sequences/$i | sed 's/|.*$//g' | sed 's/>//g' | sort | uniq -c)
            num_taxa_multicopy=$(echo "$taxa_and_counts" | awk '{{if ($1!=1) print $0}}' | wc -l)
            num_taxa_singlecopy=$(echo "$taxa_and_counts" | awk '{{if ($1==1) print $0}}' | wc -l)

            if [[ $num_taxa_multicopy -gt 0 ]]; then
                echo "multi-copy" # and run orthosnap
                ln -s $(pwd)/{input}/Orthogroup_Sequences/$i {output.multi_copy_ogs}/$i
            elif [[ $num_taxa_singlecopy -ge {params.min_seqs} ]]; then
                echo "single-copy" # and pass to alignment file
                ln -s $(pwd)/{input}/Orthogroup_Sequences/$i {output.scogs}/$i
            fi
        done
        """   


checkpoint multi_copy_ogs_min_seq_filter_orthofinder:
    """
    Copy out OGs with more than a minimum number of sequences.

    :config: ortholog_min_seqs

    % Notes - these are commented with a '%' character so they don't interefere with the markdown doc
    % -----

    % No conda env necesary as the python script only uses the stdlib.
    """
    input:
        rules.split_scogs_and_multi_copy_ogs.output.multi_copy_ogs,
    output:
        directory("results/orthofinder/multi_copy_ogs_min_seq_filtered"),
    conda:
        ENV_DIR / "typer.yaml"
    params:
        min_seqs=config.get("ortholog_min_seqs", ORTHOLOG_MIN_SEQS_DEFAULT),
    shell:
        f"python {SCRIPT_DIR}/filter_OrthoFinder.py {{input}} {{output}} {{params.min_seqs}}"
 

checkpoint orthosnap:
    """
    Run Orthosnap to retrieve single-copy orthologs.

    :output: A directory with an unknown number of fasta files.
    """
    input:
        fasta="results/orthofinder/multi_copy_ogs_min_seq_filtered/{og}.fa",
        tree="results/orthofinder/multi_copy_ogs_min_seq_filtered/{og}.nwk"
    output:
        directory("results/orthofinder/orthosnap/")
    params:
        occupancy=config.get("orthosnap_occupancy", config.get("ortholog_min_seqs", ORTHOLOG_MIN_SEQS_DEFAULT)),
    conda:
        ENV_DIR / "orthologs.yaml"
    shell:
        r"""
        orthosnap -f {input.fasta} -t {input.tree} --occupancy {params.occupancy}
        mkdir -p {output}
        mv {input.fasta}.orthosnap.*.fa {output} 2> /dev/null
        """


def list_orthofinder_scogs(wildcards):
    checkpoint_output = checkpoints.split_scogs_and_multi_copy_ogs.get(**wildcards).output.scogs
    all_ogs = glob_wildcards(os.path.join(checkpoint_output, "{og}.fa")).og
    return expand(rules.split_scogs_and_multi_copy_ogs.output.scogs, og=all_ogs)


def list_orthosnap_snap_ogs(wildcards):
    checkpoint_output = checkpoints.orthosnap.get(**wildcards).output[0]
    all_ogs = glob_wildcards(os.path.join(checkpoint_output, "{og}.fa")).og
    return expand(rules.orthosnap.output, og=all_ogs)


def combine_scogs_and_snap_ogs(wildcards):
    return list_orthofinder_scogs(wildcards) + list_orthosnap_snap_ogs(wildcards)


checkpoint orthofinder_all:
    """
    Collects all the SC-OGs and the SNAP OGs and creates symlinks for each in a single directory.

    :config: ortholog_min_seqs
    """
    input:
        combine_scogs_and_snap_ogs
    output:
        directory("results/orthofinder/all"),
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
                echo "Symlinking $(pwd)/$i to $path"
                ln -s $(pwd)/$i $path
            fi
        done
        """
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
        root=directory("results/orthofinder/output"),
        gene_trees=directory("results/orthofinder/output/Gene_Trees"),
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
        mv {params.input_dir}/OrthoFinder/Results_phyloflow/ {output.root}
        """

checkpoint split_scogs_and_multi_copy_ogs:
    """
    Takes the output of orthofinder and outputs the SCOGs.

    It is more liberal than orthofinder SCOGs.

    # TODO think about making this work per file

    :config: ortholog_min_seqs
    """
    input:
        rules.orthofinder.output.root,
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


def get_multi_copy_ogs(wildcards):
    return checkpoints.split_scogs_and_multi_copy_ogs.get(**wildcards).output.multi_copy_ogs


checkpoint generate_orthosnap_input:
    """
    Copy the OGs with more than a minimum number of sequences and copy the associated gene trees to prepare for use in orthosnap.

    :config: ortholog_min_seqs
    """
    input:
        multi_copy_ogs=get_multi_copy_ogs,
        gene_trees=rules.orthofinder.output.gene_trees
    output:
        directory("results/orthofinder/orthosnap_input"),
    conda:
        ENV_DIR / "typer.yaml"
    params:
        min_seqs=config.get("ortholog_min_seqs", ORTHOLOG_MIN_SEQS_DEFAULT),
    shell:
        f"python {SCRIPT_DIR}/generate_orthosnap_input.py {{input.multi_copy_ogs}} {{input.gene_trees}} {{output}} {{params.min_seqs}}"
 

checkpoint orthosnap:
    """
    Run Orthosnap to retrieve single-copy orthologs.

    :output: A directory with an unknown number of fasta files.
    :config: orthosnap_occupancy by default it uses ortholog_min_seqs
    """
    input:
        fasta="results/orthofinder/orthosnap_input/{og}.fa",
        tree="results/orthofinder/orthosnap_input/{og}.nwk"
    output:
        directory("results/orthofinder/orthosnap/{og}")
    params:
        occupancy=config.get("orthosnap_occupancy", config.get("ortholog_min_seqs", ORTHOLOG_MIN_SEQS_DEFAULT)),
    conda:
        ENV_DIR / "orthosnap.yaml"
    shell:
        r"""
        orthosnap -f {input.fasta} -t {input.tree} --occupancy {params.occupancy}
        mkdir -p {output}
        for file in $(find results/orthofinder/orthosnap_input -name '{wildcards.og}.fa.orthosnap.*.fa') ; do
            mv $file {output}
        done
        """


def list_orthofinder_scogs(wildcards):
    checkpoint_output = checkpoints.split_scogs_and_multi_copy_ogs.get(**wildcards).output.scogs
    return list(Path(checkpoint_output).glob("*.fa"))

def list_orthosnap_snap_ogs(wildcards):
    checkpoint_output = checkpoints.generate_orthosnap_input.get(**wildcards).output[0]
    multi_copy_ogs = glob_wildcards(os.path.join(checkpoint_output, "{og}.fa")).og
    snap_ogs = []
    for multi_copy_og in multi_copy_ogs:
        checkpoint_output = checkpoints.orthosnap.get(og=multi_copy_og).output[0]
        snap_ogs += list(Path(checkpoint_output).glob("*.fa"))
        print('snap_ogs', snap_ogs)

    return snap_ogs


def combine_scogs_and_snap_ogs(wildcards):
    orthofinder_use_scogs = config.get('orthofinder_use_scogs', True)
    orthofinder_use_snap_ogs = config.get('orthofinder_use_snap_ogs', True)
    if not orthofinder_use_scogs and not orthofinder_use_scogs:
        raise Exception(
            "You need to set either `orthofinder_use_scogs` or `orthofinder_use_snap_ogs` or both 
            "in the configuration file so that at least some orthologs can be used."
        )
    ogs = []
    if orthofinder_use_scogs:
        ogs += list_orthofinder_scogs(wildcards)
    if orthofinder_use_snap_ogs:
        ogs += list_orthosnap_snap_ogs(wildcards)

    return ogs


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
                og=$(basename $i)
                path={output}/$og
                echo "Symlinking $(pwd)/$i to $path"
                ln -s $(pwd)/$i $path
            fi
        done
        """
from pathlib import Path
from collections import namedtuple
import re

use_orthofisher = config.get('use_orthofisher', USE_ORTHOFISHER_DEFAULT)
orthofinder_use_scogs = config.get('orthofinder_use_scogs', True)
orthofinder_use_snap_ogs = config.get('orthofinder_use_snap_ogs', True)

rule orthofinder:
    """
    Runs `OrthoFinder <https://github.com/davidemms/OrthoFinder>`_ on fasta files from the intake rule.

    OrthoFinder runs to the point of orthogroup inference.
    """
    input:
        protein_files
    output:
        directory("results/orthofinder/output"),
    conda:
        ENV_DIR / "orthofinder.yaml"
    log:
        LOG_DIR / "orthofinder/orthofinder.log"
    # bibs:
    #     "../bibs/orthofinder.ris",
    params:
        input_dir="results/intake/protein",
    threads: workflow.cores
    benchmark:
        "bench/orthofinder.benchmark.txt"
    shell:
        """
        mkdir -p results/orthofinder &> {log}
        orthofinder -f {params.input_dir} -t {threads} -n orthoflow -og -X 2>> {log}
        mv {params.input_dir}/OrthoFinder/Results_orthoflow/ {output} 2>> {log}
        """


checkpoint orthogroup_classification:
    """
    Classifies orthogroups as single-copy or multi-copy or rejects them for not having enough sequences or taxa.
    """
    input:
        rules.orthofinder.output
    output:
        mcogs="results/orthofinder/mcogs.txt",
        scogs="results/orthofinder/scogs.txt",
    conda:
        ENV_DIR / "joblib.yaml"
    params:
        min_seqs=max(3,config.get("ortholog_min_seqs", ORTHOLOG_MIN_SEQS_DEFAULT)),
        min_taxa=config.get("ortholog_min_taxa", ORTHOLOG_MIN_TAXA_DEFAULT),
    log:
        LOG_DIR / "orthofinder/orthogroup_classification.log"
    benchmark:
        "bench/orthogroup_classification.benchmark.txt"
    shell:
        """
        python {SCRIPT_DIR}/orthogroup_classification.py \
            {input}/Orthogroup_Sequences/ \
            --mcogs {output.mcogs} \
            --scogs {output.scogs} \
            --min-seqs {params.min_seqs} \
            --min-taxa {params.min_taxa} &> {log}
        """


rule orthosnap:
    """
    Run Orthosnap to retrieve single-copy orthologs.

    :output: A directory with an unknown number of fasta files.
    :config orthosnap_occupancy: by default it uses ortholog_min_seqs
    """
    input:
        "results/orthofinder/output/Orthogroup_Sequences/{og}.fa"
    output:
        alignment=temp("results/orthofinder/tmp/{og}.aln"),
        tree=temp("results/orthofinder/tmp/{og}.nwk"),
        snap_ogs=directory("results/orthofinder/orthosnap/{og}")
    params:
        occupancy=config.get("orthosnap_occupancy", max(3,config.get("ortholog_min_seqs", ORTHOLOG_MIN_SEQS_DEFAULT))),
    conda:
        ENV_DIR / "orthosnap.yaml"
    log:
        LOG_DIR / "orthofinder/orthosnap/{og}.log"
    benchmark:
        "bench/orthosnap.{og}.benchmark.txt"
    shell:
        """
        {{ mafft {input} > {output.alignment} ; }} &> {log}
        {{ fasttree {output.alignment} > {output.tree} ; }} 2>> {log}
        orthosnap -f {output.alignment} -t {output.tree} --occupancy {params.occupancy} 2>> {log}
        
        mkdir -p {output.snap_ogs} 2>> {log}
        for file in $(find results/orthofinder/tmp -name '{wildcards.og}.aln.orthosnap.*.fa') ; do
            mv $file {output.snap_ogs}/$(basename $file | sed 's/\.aln\.orthosnap\./_orthosnap_/g') 2>> {log}
        done
        """


rule orthofinder_report_components:
    """
    Converts the orthofinder output to HTML components that will be used in the Orthoflow report.
    """
    input:
        rules.orthofinder.output
    output:
        directory("results/orthofinder/report"),   
    conda:
        ENV_DIR / "summary.yaml"
    log:
        LOG_DIR / "orthofinder/orthofinder_report_components.log"
    benchmark:
        "bench/orthofinder_report_components.benchmark.txt"
    shell:
        "python {SCRIPT_DIR}/orthofinder_report_components.py {input} {output} &> {log}"


def list_orthofinder_mcogs(wildcards):
    """ 
    Returns a list of all the multi copy orthogroups available for downstream analysis.
    
    Returns an empty list if the config species to use Orthofisher instead of OrthoFinder or if the config says to not use SNAP-OGs.
    """
    if use_orthofisher or not orthofinder_use_snap_ogs:
        return []

    checkpoint_output = checkpoints.orthogroup_classification.get(**wildcards).output.mcogs
    mcogs = Path(checkpoint_output).read_text().strip().split("\n")
    
    mcog_str = Path(checkpoint_output).read_text().strip()
    return mcog_str.split("\n") if mcog_str else []


def list_snap_og_dirs(wildcards):
    """ 
    Returns a list of all the SNAP orthogroups available for downstream analysis.
    
    These are produced by running Orthosnap on the multi-copy orthogroups.
    Returns an empty list if the config species to use Orthofisher instead of OrthoFinder or if the config says to not user SNAP-OGs.
    """
    if use_orthofisher or not orthofinder_use_snap_ogs:
        return []

    multi_copy_ogs = list_orthofinder_mcogs(wildcards)
    snap_og_dirs = []
    for multi_copy_og_path in multi_copy_ogs:
        og = Path(multi_copy_og_path).name.split(".")[0]
        snap_og_dirs.append(f"results/orthofinder/orthosnap/{og}")
    return snap_og_dirs


rule write_snap_ogs_list:
    """
    Lists all the SNAP OGs and lists them in a file.
    """
    input:
        list_snap_og_dirs
    output:
        snap_ogs="results/orthofinder/orthosnap/snap-ogs.txt",
    log:
        LOG_DIR / "orthofinder/write_snap_ogs_list.log"
    benchmark:
        "bench/write_snap_ogs_list.benchmark.txt"
    shell:
        """
        for SNAPOG_DIR in {input} ; do 
            echo ${{SNAPOG_DIR}}
            find ${{SNAPOG_DIR}} -name '*.fa' >> {output}
        done
        """


checkpoint orthofinder_all:
    """
    Collects all the SC-OGs and the SNAP OGs and creates symlinks for each in a single directory.

    :config ortholog_min_seqs: Minimum number of sequences that needs to be in an alignment for it to proceed to phylogenetic analysis
    """
    input:
        scogs=rules.orthogroup_classification.output.scogs,
        snap_ogs=rules.write_snap_ogs_list.output.snap_ogs,
    output:
        directory("results/orthofinder/all"),
    params:
        min_seqs=max(3,config.get("ortholog_min_seqs", ORTHOLOG_MIN_SEQS_DEFAULT)),
    log:
        LOG_DIR / "orthofinder/orthofinder_all.log"
    benchmark:
        "bench/orthofinder_all.benchmark.txt"
    shell:
        """
        mkdir -p {output} &> {log}
        for LIST in {input}; do
            for i in $(cat $LIST); do
                nseq=$(grep ">" $i | wc -l)

                if [[ $nseq -ge {params.min_seqs} ]]; then
                    og=$(basename $i)
                    path={output}/$og
                    echo "Symlinking $(pwd)/$i to $path" 2>> {log}
                    ln -s ../../../$i $path 2>> {log}
                fi
            done
        done
        """
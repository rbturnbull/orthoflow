from pathlib import Path
from collections import namedtuple
import re

use_orthofisher = config.get('use_orthofisher', USE_ORTHOFISHER_DEFAULT)
orthofinder_use_scogs = config.get('orthofinder_use_scogs', True)
orthofinder_use_snap_ogs = config.get('orthofinder_use_snap_ogs', True)


checkpoint orthofinder:
    """
    Runs `OrthoFinder <https://github.com/davidemms/OrthoFinder>`_ on fasta files from the intake rule.

    OrthoFinder runs to the point of orthogroup inference.
    """
    input:
        input_csv['file'].map(lambda f: f"results/intake/translated/{f.split('.')[0]}.protein.fa"),
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
        orthofinder -f {params.input_dir} -t {threads} -n orthoflow -og -X
        mv {params.input_dir}/OrthoFinder/Results_orthoflow/ {output}
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
        min_seqs=config.get("ortholog_min_seqs", ORTHOLOG_MIN_SEQS_DEFAULT),
        min_taxa=config.get("ortholog_min_taxa", ORTHOLOG_MIN_TAXA_DEFAULT),
    shell:
        """
        python {SCRIPT_DIR}/orthogroup_classification.py \
            {input}/Orthogroup_Sequences/ \
            --mcogs {output.mcogs} \
            --scogs {output.scogs} \
            --min-seqs {params.min_seqs} \
            --min-taxa {params.min_taxa}
        """


def list_orthofinder_ogs(wildcards):
    checkpoint_output = checkpoints.orthofinder.get(**wildcards).output
    sequences_dir = Path(checkpoint_output[0])/"Orthogroup_Sequences"
    ogs = [path.name.split(".")[0] for path in sequences_dir.glob("*.fa")]
    filtered_reports = [f"results/orthofinder/filtered-report/{og}.txt" for og in ogs]
    return filtered_reports


checkpoint list_orthofinder_ogs_rule:
    input:
        list_orthofinder_ogs
    output:
        "results/list_orthofinder_ogs.txt"
    shell:
        "echo {input} > {output}"


checkpoint orthosnap:
    """
    Run Orthosnap to retrieve single-copy orthologs.

    :output: A directory with an unknown number of fasta files.
    :config orthosnap_occupancy: by default it uses ortholog_min_seqs
    """
    input:
        "results/orthofinder/mcogs/{og}.fa"
    output:
        alignment=temp("results/orthofinder/tmp/{og}.aln"),
        tree=temp("results/orthofinder/tmp/{og}.nwk"),
        snap_ogs=directory("results/orthofinder/orthosnap/{og}")
    params:
        occupancy=config.get("orthosnap_occupancy", config.get("ortholog_min_seqs", ORTHOLOG_MIN_SEQS_DEFAULT)),
    conda:
        ENV_DIR / "orthosnap.yaml"
    shell:
        r"""
        mafft {input} > {output.alignment}
        fasttree {output.alignment} > {output.tree}
        orthosnap -f {output.alignment} -t {output.tree} --occupancy {params.occupancy}
        
        mkdir -p {output.snap_ogs}
        for file in $(find results/orthofinder/tmp -name '{wildcards.og}.aln.orthosnap.*.fa') ; do
            basename $file
            basename $file | sed 's/\.aln\.orthosnap\./_orthosnap_/g'
            mv $file {output.snap_ogs}/$(basename $file | sed 's/\.aln\.orthosnap\./_orthosnap_/g')
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
    shell:
        "python {SCRIPT_DIR}/orthofinder_report_components.py {input} {output}"



def list_orthofinder_scogs(wildcards):
    if use_orthofisher or not orthofinder_use_scogs:
        return []

    checkpoint_output = checkpoints.split_scogs_and_multi_copy_ogs.get(**wildcards).output.scogs
    return list(Path(checkpoint_output).glob("*.fa"))


def list_orthosnap_snap_ogs(wildcards):
    if use_orthofisher or not orthofinder_use_snap_ogs:
        return []

    checkpoint_output = checkpoints.generate_orthosnap_input.get(**wildcards).output[0]
    multi_copy_ogs = glob_wildcards(os.path.join(checkpoint_output, "{og}.fa")).og
    snap_ogs = []
    for multi_copy_og in multi_copy_ogs:
        checkpoint_output = checkpoints.orthosnap.get(og=multi_copy_og).output[0]
        snap_ogs += list(Path(checkpoint_output).glob("*.fa"))

    return snap_ogs


def combine_scogs_and_snap_ogs(wildcards):
    if not orthofinder_use_scogs and not orthofinder_use_snap_ogs:
        raise Exception(
            "You need to set either `orthofinder_use_scogs` or `orthofinder_use_snap_ogs` or both "
            "in the configuration file so that at least some orthologs can be used."
        )

    all_ogs = list_orthofinder_scogs(wildcards) + list_orthosnap_snap_ogs(wildcards)
    if len(all_ogs) == 0:
        raise Exception("No orthogroups found. Please check your input file.")

    return all_ogs


checkpoint orthofinder_all:
    """
    Collects all the SC-OGs and the SNAP OGs and creates symlinks for each in a single directory.

    :config ortholog_min_seqs: Minimum number of sequences that needs to be in an alignment for it to proceed to phylogenetic analysis
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
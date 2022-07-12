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
        ENV_DIR / "orthologs.yaml"
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

checkpoint min_seq_filter_orthofinder:
    """
    Copy out OGs with more than a minimum number of sequences.

    :config: ortholog_min_seqs

    % Notes - these are commented with a '%' character so they don't interefere with the markdown doc
    % -----

    % No conda env necesary as the python script only uses the stdlib.
    """
    input:
        rules.orthofinder.output,
    output:
        directory("results/orthofinder/min-seq-filtered"),
    conda:
        ENV_DIR / "orthologs.yaml"
    params:
        min_seqs=config.get("ortholog_min_seqs", 1),
    shell:
        f"python {SCRIPT_DIR}/filter_OrthoFinder.py {{input}} {{output}} {{params.min_seqs}}"


rule orthosnap:
    """
    Run Orthosnap to retrieve single-copy orthologs.

    :output: A directory with an unknown number of fasta files.
    """
    input:
        fasta="results/orthofinder/min-seq-filtered/{og}.fa",
        tree="results/orthofinder/min-seq-filtered/{og}.nwk"
    output:
        "results/orthofinder/orthosnap/{og}.fa"
    params:
        occupancy=config.get("orthosnap_occupancy", 1),
    conda:
        ENV_DIR / "orthologs.yaml"
    shell:
        r"""
        rm -f results/orthologs/{wildcards.og}*orthosnap*
        orthosnap -f {input.fasta} -t {input.tree} --occupancy {params.occupancy}

        # NOTE: We need to use a loop to ensure we do nothing if there are no glob matches
        snapfiles=$(ls {input.fasta}.orthosnap.*.fa 2> /dev/null || true)
        for f in $snapfiles; do
            cat $f >> {output}
            rm $f
        done
        """


def orthofinder_aggregation(wildcards):
    checkpoint_output = checkpoints.min_seq_filter_orthofinder.get(**wildcards).output[0]
    all_ogs = glob_wildcards(os.path.join(checkpoint_output, "{og}.fa")).og
    return expand(rules.orthosnap.output, og=all_ogs)


checkpoint orthofinder_all:
    """
    Collects all the SC-OGs and the SNAP OGs and creates symlinks for each in a single directory.

    :config: ortholog_min_seqs
    """
    input:
        orthofinder_aggregation
    output:
        directory("results/orthofinder/all"),
    params:
        min_seqs=config.get("ortholog_min_seqs", 1),
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
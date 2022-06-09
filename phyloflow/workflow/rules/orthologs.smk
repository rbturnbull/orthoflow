from pathlib import Path
from collections import namedtuple
import re


rule orthofinder:
    """
    Runs `OrthoFinder <https://github.com/davidemms/OrthoFinder>`_ on fasta files from the intake rule.
    """
    input:
        pd.read_csv("input_sources.csv")['file'].map(lambda f: f"results/translated/{f.split('.')[0]}.cds.fasta"),
    output:
        directory("results/translated/OrthoFinder/Results_phyloflow"),
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
        orthofinder -f {params.input_dir} -t {threads} -n phyloflow -ot -M msa -X
        """


checkpoint filter_orthofinder:
    """
    Copy out OGs with more than a minimum number of sequences.

    :config: filter_orthofinder

    % Notes - these are commented with a '%' character so they don't interefere with the markdown doc
    % -----

    % No conda env necesary as the python script only uses the stdlib.
    """
    input:
        rules.orthofinder.output,
    output:
        directory("results/orthologs"),
    conda:
        ENV_DIR / "orthologs.yaml"
    params:
        min_seq=config["filter_orthofinder"]['min_sequences'],
    shell:
        f"python {SCRIPT_DIR}/filter_OrthoFinder.py {{input}} {{output}} {{params.min_seq}}"


rule orthosnap:
    """
    Run Orthosnap to retrieve single-copy orthologs.

    To get orthosnap to run, we had to modify the IDs in the fasta files using the filter_orthofinder script to replace ';' with  '_'.
    Later we will want to back match these IDs against the original CDS, so we have to reverse this transformation here!

    :output: A directory with an unknown number of
    """
    input:
        fasta="results/orthologs/{og}.fa",
        tree="results/orthologs/{og}.nwk"
    output:
        "results/orthologs/{og}.orthosnap.fa"
    conda:
        ENV_DIR / "orthologs.yaml"
    shell:
        r"""
        orthosnap -f {input.fasta} -t {input.tree}

        for f in {input.fasta}.orthosnap.*.fa; do  # N.B. This for loop just checks to ensure we have any matching files
            cat {input.fasta}.orthosnap.*.fa > {output} || true
            break
        done
        """

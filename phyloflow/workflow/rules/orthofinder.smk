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
        directory("results/orthofinder"),
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
        directory("results/orthofinder-filtered"),
    conda:
        ENV_DIR / "orthologs.yaml"
    params:
        min_seqs=config["ortholog_min_seqs"],
    shell:
        f"python {SCRIPT_DIR}/filter_OrthoFinder.py {{input}} {{output}} {{params.min_seqs}}"


checkpoint orthosnap:
    """
    Run Orthosnap to retrieve single-copy orthologs.

    To get orthosnap to run, we had to modify the IDs in the fasta files using the filter_orthofinder script to replace ';' with  '_'.
    Later we will want to back match these IDs against the original CDS, so we have to reverse this transformation here!

    :output: A directory with an unknown number of
    """
    input:
        fasta="results/orthofinder-filtered/{og}.fa",
        tree="results/orthofinder-filtered/{og}.nwk"
    output:
        touch("results/orthologs/.{og}.orthosnap.flag")
    conda:
        ENV_DIR / "orthologs.yaml"
    shell:
        r"""
        orthosnap -f {input.fasta} -t {input.tree}

        # NOTE: We need to use a loop to ensure we do nothing if there are no glob matches
        snapfiles=$(ls {input.fasta}.orthosnap.*.fa 2> /dev/null || true)
        for f in $snapfiles; do
            cat $f >> results/orthofinder-filtered/{wildcards.og}.orthosnap.fa
        done
        """

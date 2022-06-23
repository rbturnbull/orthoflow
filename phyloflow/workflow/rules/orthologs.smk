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


checkpoint orthosnap:
    """
    Run Orthosnap to retrieve single-copy orthologs.

    :output: A directory with an unknown number of fasta files.
    """
    input:
        fasta="results/orthologs/{og}.fa",
        tree="results/orthologs/{og}.nwk"
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
            cat $f >> results/orthologs/{wildcards.og}.orthosnap.fa
        done
        """

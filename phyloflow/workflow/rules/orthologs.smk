from pathlib import Path
from collections import namedtuple


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

    :output: A directory with an unknown number of
    """
    input:
        fasta="results/orthologs/{id}.fa",
        tree="results/orthologs/{id}.nwk"
    output:
        directory("results/orthologs/{id}.fa.orthosnap")
    conda:
        ENV_DIR / "orthologs.yaml"
    shell:
        """
        mkdir {output}
        orthosnap -f {input.fasta} -t {input.tree}
        mv {output}.*.fa {output} || true
        """

rule combine_subgroups:
    input:
        lambda wildcards: [
                f"{fasta}.orthosnap"
                for fasta in Path(checkpoints.filter_orthofinder.get(**wildcards).output[0]).glob("*.fa")
            ]
    output:
        "results/combined_sc_orthologs.fa"
    shell:
        "cat results/orthologs/*.orthosnap/* > {output}"

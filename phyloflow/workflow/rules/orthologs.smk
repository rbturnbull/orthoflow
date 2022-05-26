from pathlib import Path


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
    params:
        input_dir=lambda wildcards, input: Path(input[0]).parent,
    threads: workflow.cores
    shell:
        """
        orthofinder -f {params.input_dir} -t {threads} -n phyloflow
        """


rule filter_orthofinder:
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

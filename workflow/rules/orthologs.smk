from pathlib import Path


rule orthofinder:
    """
    Runs `OrthoFinder <https://github.com/davidemms/OrthoFinder>`_ on fasta files from the intake rule.
    """
    input:
        pd.read_csv("input_sources.csv")['file'].map(
            lambda f: f"results/translated/{f.split('.')[0]}.cds.fasta"
        ),
    output:
        temp(directory("translated/OrthoFinder")),
    conda:
        ENV_DIR / "orthofinder.yaml"
    params:
        input_dir=lambda wildcards, input: Path(input[0]).parent,
    shell:
        "orthofinder -d -f {params.input_dir}"


rule filter_orthofinder:
    """
    Copy out OGs with more than a minimum number of sequences.

    :config: filter_orthofinder

    Notes
    -----

    No conda env necesary as the python script only uses the stdlib.
    """
    input:
        rules.orthofinder.output,
    output:
        directory("results/orthologs"),
    params:
        min_seq=config["filter_orthofinder"]['min_sequences'],
    shell:
        "python scripts/filter_OrthoFinder.py -i {input} -o {output} -m {params.min_seq}"

rule concatenate_alignments:
    """
    Concatenate alignments into a single supermatrix.

    https://jlsteenwyk.com/PhyKIT/usage/index.html#create-concatenation-matrix
    """
    output:
        fasta="results/supermatrix/supermatrix.fa",
        partition="results/supermatrix/supermatrix.partition",
        occupancy="results/supermatrix/supermatrix.occupancy",
    input:
        rules.list_alignments.output
    conda:
        "../envs/phykit.yaml"
    bibs:
        "../bibs/phykit.bib"
    log:
        "logs/supermatrix/supermatrix.log"
    shell:
        "phykit create_concatenation_matrix --alignment {input} --prefix results/supermatrix/supermatrix"


rule alignment_summary:
    """
    Summarizes the supermatrix alignment using BioKIT

    https://jlsteenwyk.com/BioKIT/usage/index.html#alignment-summary
    https://jlsteenwyk.com/tutorials/phylogenomics_made_easy.html
    """
    output:
        "results/supermatrix/alignment_summary.txt",
    input:
        rules.concatenate_alignments.output.fasta
    conda:
        "../envs/biokit.yaml"
    bibs:
        "../bibs/biokit.bib",
    log:
        "logs/supermatrix/alignment_summary.log"
    shell:
        "biokit alignment_summary {input} > {output}"


rule iqtree:
    """
    Use IQTREE on the supermatrix.
    """
    output:
        "results/supermatrix/supermatrix.fa.treefile",
    input:
        rules.concatenate_alignments.output.fasta
    threads: 
        workflow.cores
    conda:
        "../envs/iqtree.yaml"
    bibs:
        "../bibs/iqtree2.bib",
        "../bibs/ultrafast-bootstrap.bib",
        "../bibs/modelfinder.ris",
    log:
        "logs/supermatrix/iqtree.log"
    shell:
        "iqtree2 -s {input} -bb 1000 -m TEST -ntmax {threads} -redo"

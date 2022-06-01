rule concatenate_alignments:
    """
    Concatenate alignments into a single supermatrix.

    https://jlsteenwyk.com/PhyKIT/usage/index.html#create-concatenation-matrix
    """
    output:
        "results/supermatrix/supermatrix.fa",
        "results/supermatrix/supermatrix.partition",
        "results/supermatrix/supermatrix.occupancy",
    input:
        rules.list_alignments.output
    conda:
        "../envs/phykit.yaml"
    bibs:
        "../bibs/phykit.bib"
    log:
        "logs/phykit_concat/supermatrix.log"
    shell:
        "phykit create_concatenation_matrix --alignment {input} --prefix results/supermatrix/supermatrix"


# do we want to get an alignment_summary?
# https://jlsteenwyk.com/tutorials/phylogenomics_made_easy.html

rule iqtree:
    """
    Use IQTREE on the supermatrix.
    """
    output:
        "results/supermatrix/supermatrix.fa.treefile",
    input:
        rules.concatenate_alignments.output
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
        "iqtree2 -s {input} -bb 1000 -m TEST -ntmax {threads}"

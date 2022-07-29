



rule gene_tree_iqtree:
    """
    Use IQTREE on the gene alignments.
    """
    input:
        rules.trim_alignments.output
    output:
        report("results/gene_tree/{og}/{og}.treefile", category="Gene Tree"),

    threads: 
        workflow.cores
    conda:
        "../envs/iqtree.yaml"
    bibs:
        "../bibs/iqtree2.bib",
        "../bibs/ultrafast-bootstrap.bib",
        "../bibs/modelfinder.ris",
    log:
        "logs/gene_tree/iqtree-{og}.log"
    shell:
        """
        mkdir -p results/gene_tree/{wildcards.og}
        iqtree2 -s {input} -bb 1000 -m TEST -ntmax {threads} -pre results/gene_tree/{wildcards.og}/{wildcards.og} -redo
        """


rule gene_tree_ascii:
    """
    Displays the tree in ASCII format.
    """
    input:
        rules.gene_tree_iqtree.output
    output:
        report("results/gene_tree/ascii/{og}.txt", category="Gene Tree"),
    conda:
        "../envs/phykit.yaml"
    bibs:
        "../bibs/phykit.bib",
    log:
        "logs/supermatrix/print_ascii_tree-{og}.log"
    shell:
        "phykit print_tree {input} > {output}"

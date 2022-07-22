



rule gene_tree_iqtree:
    """
    Use IQTREE on the gene alignments.
    """
    input:
        rules.trim_alignments.output
    output:
        directory("results/gene_tree/{og}"),
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
        mkdir -p {output}
        iqtree2 -s {input} -bb 1000 -m TEST -ntmax {threads} -pre {output}/{og} -redo
        """


rule ascii_gene_tree:
    """
    Displays the tree in ASCII format.
    """
    input:
        "results/gene_tree/{og}/{og}.treefile"
    output:
        report("results/gene_tree/{og}/ascii_tree.txt", category="Gene Tree"),
    conda:
        "../envs/phykit.yaml"
    bibs:
        "../bibs/phykit.bib",
    log:
        "logs/supermatrix/print_ascii_tree-{og}.log"
    shell:
        "phykit print_tree {input}/1080at3041.treefile > {output}"

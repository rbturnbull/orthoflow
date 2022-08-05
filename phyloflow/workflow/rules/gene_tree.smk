



rule gene_tree_iqtree:
    """
    Use IQTREE on the gene alignments.
    """
    input:
        rules.trim_alignments.output
    output:
        report(f"results/gene_tree/{{og}}/{{og}}.{alignment_type}.treefile", category="Gene Tree"),
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
    params:
        bootstrap_string=config.get("bootstrap_string", BOOTSTRAP_STRING_DEFAULT),
        model_string=config.get("model_string", MODEL_STRING_DEFAULT),
    shell:
        """
        mkdir -p results/gene_tree/{wildcards.og}
        iqtree2 -s {input} {params.bootstrap_string} {params.model_string} -ntmax {threads} -pre results/gene_tree/{wildcards.og}/{wildcards.og} -redo
        """

rule gene_tree_ascii:
    """
    Displays the tree in ASCII format.
    """
    input:
        rules.gene_tree_iqtree.output
    output:
        f"results/gene_tree/ascii/{{og}}_tree_ascii.{alignment_type}.txt",
    conda:
        "../envs/phykit.yaml"
    bibs:
        "../bibs/phykit.bib",
    log:
        "logs/supermatrix/print_ascii_tree-{og}.log"
    shell:
        "phykit print_tree {input} > {output}"

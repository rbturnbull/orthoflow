
rule gene_tree_iqtree:
    """
    Use IQTREE on the gene alignments.
    """
    input:
        rules.trim_alignments.output
    output:
        treefile="results/gene_tree/{og}/{og}.{alignment_type}.treefile",
        consensus_tree=temp("results/gene_tree/{og}/{og}.{alignment_type}.contree"),
        iqtree_report=temp("results/gene_tree/{og}/{og}.{alignment_type}.iqtree"),
        iqtree_log="results/gene_tree/{og}/{og}.{alignment_type}.log",
    threads: 
        1
    conda:
        ENV_DIR / "iqtree.yaml"
    # bibs:
    #     "../bibs/iqtree2.bib",
    #     "../bibs/ultrafast-bootstrap.bib",
    #     "../bibs/modelfinder.ris",
    params:
        bootstrap_string=config.get("bootstrap_string", BOOTSTRAP_STRING_DEFAULT),
        model_string=config.get("model_string", MODEL_STRING_DEFAULT),
    shell:
        """
        mkdir -p results/gene_tree/{wildcards.og}
        iqtree2 -s {input} {params.bootstrap_string} {params.model_string} -nt {threads} -mset mrbayes -pre results/gene_tree/{wildcards.og}/{wildcards.og}.{wildcards.alignment_type} -redo
        """


rule gene_tree_ascii:
    """
    Displays the gene tree in ASCII format.
    """
    input:
        rules.gene_tree_iqtree.output.treefile
    output:
        "results/gene_tree/{og}/{og}_tree_ascii.{alignment_type}.txt",
    conda:
        ENV_DIR / "phykit.yaml"
    # bibs:
    #     "../bibs/phykit.bib",
    threads: 
        1
    shell:
        "phykit print_tree {input} > {output}"


rule gene_tree_render:
    """
    Renders the gene tree in SVG and PNG formats.
    """
    input:
        rules.gene_tree_iqtree.output.treefile
    output:
        svg="results/gene_tree/{og}/{og}.{alignment_type}.tree.svg",
    conda:
        ENV_DIR / "toytree.yaml"
    # bibs:
    #     "../bibs/toytree.bib",
    threads: 
        1
    shell:
        "python {SCRIPT_DIR}/render_tree.py {input} --svg {output.svg}"


rule gene_tree_consensus_render:
    """
    Renders the consensus gene tree tree in SVG and PNG formats.
    """
    input:
        rules.gene_tree_iqtree.output.consensus_tree
    output:
        svg="results/gene_tree/{og}/{og}.{alignment_type}.consensus-tree.svg",
    conda:
        ENV_DIR / "toytree.yaml"
    # bibs:
    #     "../bibs/toytree.bib",
    threads: 
        1
    shell:
        "python {SCRIPT_DIR}/render_tree.py {input} --svg {output.svg}"

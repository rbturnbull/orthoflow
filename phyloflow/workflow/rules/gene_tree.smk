
rule gene_tree_iqtree:
    """
    Use IQTREE on the gene alignments.
    """
    input:
        rules.trim_alignments.output
    output:
        treefile=f"results/gene_tree/{{og}}/{{og}}.{alignment_type}.treefile",
        consensus_tree=f"results/gene_tree/{{og}}/{{og}}.{alignment_type}.contree",
        iqtree_report=f"results/gene_tree/{{og}}/{{og}}.{alignment_type}.iqtree",
        iqtree_log=f"results/gene_tree/{{og}}/{{og}}.{alignment_type}.log",
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
        iqtree2 -s {input} {params.bootstrap_string} {params.model_string} -ntmax {threads} -pre results/gene_tree/{wildcards.og}/{wildcards.og}.{alignment_type} -redo
        """


rule gene_tree_ascii:
    """
    Displays the gene tree in ASCII format.
    """
    input:
        rules.gene_tree_iqtree.output
    output:
        f"results/gene_tree/{{og}}/{{og}}_tree_ascii.{alignment_type}.txt",
    conda:
        "../envs/phykit.yaml"
    bibs:
        "../bibs/phykit.bib",
    log:
        "logs/supermatrix/print_ascii_tree-{og}.log"
    shell:
        "phykit print_tree {input} > {output}"


rule gene_tree_render:
    """
    Renders the gene tree in SVG and PNG formats.
    """
    input:
        rules.gene_tree_iqtree.output.treefile
    output:
        svg=f"results/gene_tree/{{og}}/{{og}}.{alignment_type}.tree.svg",
        png=f"results/gene_tree/{{og}}/{{og}}.{alignment_type}.tree.png",
    conda:
        "../envs/toytree.yaml"
    bibs:
        "../bibs/toytree.bib",
    shell:
        "python {SCRIPT_DIR}/render_tree.py {input} --svg {output.svg} --png {output.png}"


rule gene_tree_consensus_render:
    """
    Renders the consensus gene tree tree in SVG and PNG formats.
    """
    input:
        rules.gene_tree_iqtree.output.consensus_tree
    output:
        svg=f"results/gene_tree/{{og}}/{{og}}.{alignment_type}.consensus-tree.svg",
        png=f"results/gene_tree/{{og}}/{{og}}.{alignment_type}.consensus-tree.png",
    conda:
        "../envs/toytree.yaml"
    bibs:
        "../bibs/toytree.bib",
    shell:
        "python {SCRIPT_DIR}/render_tree.py {input} --svg {output.svg} --png {output.png}"

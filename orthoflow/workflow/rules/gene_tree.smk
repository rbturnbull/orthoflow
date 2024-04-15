
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


def list_gene_tree_files(wildcards, extension):
    alignments_text_file = checkpoints.check_presence_after_filtering.get(**wildcards).output[0]
    alignments = Path(alignments_text_file).read_text().strip().split("\n")

    gene_trees = []
    for alignment in alignments:
        alignment = Path(alignment)
        og = alignment.name.split(".")[0]
        gene_trees.append(f"results/gene_tree/{og}/{og}.{wildcards.alignment_type}.{extension}")

    return gene_trees


def list_gene_trees(wildcards):
    """
    Returns a list of the treefiles for all the genes.
    """
    return list_gene_tree_files(wildcards, extension="treefile")


rule gene_tree_summary:
    """
    Creates plots of Gene Tree results
    """
    input:
        genetree_iqtree_reports=partial(list_gene_tree_files, extension="iqtree"),
    output:
        genetree_iqtree_reports_list="results/gene_tree/summary/gene_tree_reports.{alignment_type}.txt",
        csv="results/gene_tree/summary/gene_tree_summary.{alignment_type}.csv",
        plot=report("results/gene_tree/summary/gene_tree_summary.{alignment_type}.svg", category="Summary"),
        model_plot_html=report("results/gene_tree/summary/model.{alignment_type}.html", category="Summary"),
        model_plot_image=report("results/gene_tree/summary/model.{alignment_type}.pdf", category="Summary"),
        state_frequencies_plot_html=report("results/gene_tree/summary/state_frequencies.{alignment_type}.html", category="Summary"),
        state_frequencies_plot_image=report("results/gene_tree/summary/state_frequencies.{alignment_type}.pdf", category="Summary"),
    conda:
        "../envs/summary.yaml"
    log:
        LOG_DIR / "results/gene_tree/gene_tree_summary.{alignment_type}.log",
    shell:
        """
        echo {input.genetree_iqtree_reports} > {output.genetree_iqtree_reports_list} 
        python {SCRIPT_DIR}/gene_tree_summary.py \
            {output.genetree_iqtree_reports_list} \
            {output.csv} \
            {output.plot} \
            {output.model_plot_html} \
            {output.model_plot_image} \
            {output.state_frequencies_plot_html} \
            {output.state_frequencies_plot_image} 2>&1 | tee {log}
        """

rule concatenate_alignments:
    """
    Concatenate alignments into a single supermatrix.

    https://jlsteenwyk.com/PhyKIT/usage/index.html#create-concatenation-matrix
    """
    input:
        rules.list_alignments.output
    output:
        fasta=f"results/supermatrix/supermatrix.{alignment_type}.fa",
        partition=f"results/supermatrix/supermatrix.{alignment_type}.partition",
        occupancy=f"results/supermatrix/supermatrix.{alignment_type}.occupancy",
    conda:
        "../envs/phykit.yaml"
    bibs:
        "../bibs/phykit.bib"
    log:
        "logs/supermatrix/supermatrix.log"
    shell:
        "phykit create_concatenation_matrix --alignment {input} --prefix results/supermatrix/supermatrix.{alignment_type}"


rule alignment_summary:
    """
    Summarizes the supermatrix alignment using BioKIT

    https://jlsteenwyk.com/BioKIT/usage/index.html#alignment-summary
    https://jlsteenwyk.com/tutorials/phylogenomics_made_easy.html
    """
    input:
        rules.concatenate_alignments.output.fasta
    output:
        f"results/supermatrix/alignment_summary.{alignment_type}.txt"
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
    input:
        rules.concatenate_alignments.output.fasta
    output:
        treefile=report("results/supermatrix/supermatrix.{alignment_type}.fa.treefile", category="Supermatrix"),
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


rule supermatrix_ascii:
    """
    Displays the tree in ASCII format.
    """
    input:
        rules.iqtree.output.treefile
    output:
        report("results/supermatrix/supermatrix_tree_ascii.{alignment_type}.txt", category="Supermatrix"),
    conda:
        "../envs/phykit.yaml"
    bibs:
        "../bibs/phykit.bib",
    log:
        "logs/supermatrix/print_ascii_tree.log"
    shell:
        "phykit print_tree {input} > {output}"


rule supermatrix_render:
    """
    Renders the tree in SVG and PNG formats.
    """
    input:
        rules.iqtree.output.treefile
    output:
        svg=report("results/supermatrix/supermatrix_tree_render.{alignment_type}.svg", category="Supermatrix"),
        png=report("results/supermatrix/supermatrix_tree_render.{alignment_type}.png", category="Supermatrix"),
    conda:
        "../envs/toytree.yaml"
    bibs:
        "../bibs/toytree.bib",
    log:
        "logs/supermatrix/render_tree.log"
    shell:
        "python {SCRIPT_DIR}/render_tree.py {input} --svg {output.svg} --png {output.png} --html {output.html}"



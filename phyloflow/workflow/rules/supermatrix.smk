rule concatenate_alignments:
    """
    Concatenate alignments into a single supermatrix.

    https://jlsteenwyk.com/PhyKIT/usage/index.html#create-concatenation-matrix
    """
    input:
        rules.list_alignments.output
    output:
        fasta="results/supermatrix/supermatrix.fa",
        partition="results/supermatrix/supermatrix.partition",
        occupancy="results/supermatrix/supermatrix.occupancy",
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
        report("results/supermatrix/alignment_summary.txt", caption="../report/alignment_summary.rst", category="Supermatrix"),
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
        treefile=report("results/supermatrix/supermatrix.fa.treefile", category="Supermatrix"),
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


rule supermatrix_ascii:
    """
    Displays the tree in ASCII format.
    """
    output:
        report("results/supermatrix/supermatrix_ascii.txt", category="Supermatrix"),
    input:
        rules.iqtree.output.treefile
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
    Renders the tree in SVG format.
    """
    output:
        svg=report("results/supermatrix/supermatrix_render.svg", category="Supermatrix"),
        html=report("results/supermatrix/supermatrix_render.html", category="Supermatrix"),
        png=report("results/supermatrix/supermatrix_render.png", category="Supermatrix"),
    input:
        rules.iqtree.output.treefile
    conda:
        "../envs/toytree.yaml"
    bibs:
        "../bibs/toytree.bib",
    log:
        "logs/supermatrix/render_tree.log"
    shell:
        "python {SCRIPT_DIR}/render_tree.py {input} --svg {output.svg} --png {output.png} --html {output.html}"



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


rule supermatrix_alignment_summary:
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


supermatrix_outgroup = config.get("supermatrix_outgroup", SUPERMATRIX_OUTGROUP_DEFAULT)

rule supermatrix_iqtree:
    """
    Use IQTREE on the supermatrix.
    """
    input:
        rules.concatenate_alignments.output.fasta
    output:
        treefile=f"results/supermatrix/supermatrix.{alignment_type}.fa.treefile"
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
    params:
        bootstrap_string=config.get("bootstrap_string", BOOTSTRAP_STRING_DEFAULT),
        model_string=config.get("model_string", MODEL_STRING_DEFAULT),
        supermatrix_outgroup_string=f"-o {supermatrix_outgroup}" if supermatrix_outgroup else "",
    shell:
        "iqtree2 -s {input} {params.bootstrap_string} {params.model_string} {params.supermatrix_outgroup_string} -ntmax {threads} -redo"


rule supermatrix_ascii:
    """
    Displays the tree in ASCII format.
    """
    input:
        rules.supermatrix_iqtree.output.treefile
    output:
        f"results/supermatrix/supermatrix_tree_ascii.{alignment_type}.txt"
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
        rules.supermatrix_iqtree.output.treefile
    output:
        svg=f"results/supermatrix/supermatrix_tree_render.{alignment_type}.svg",
        png=f"results/supermatrix/supermatrix_tree_render.{alignment_type}.png"
    conda:
        "../envs/toytree.yaml"
    bibs:
        "../bibs/toytree.bib",
    log:
        "logs/supermatrix/render_tree.log"
    shell:
        "python {SCRIPT_DIR}/render_tree.py {input} --svg {output.svg} --png {output.png} --html {output.html}"



rule concatenate_alignments:
    """
    Concatenate alignments into a single supermatrix.

    https://jlsteenwyk.com/PhyKIT/usage/index.html#create-concatenation-matrix
    """
    input:
        rules.list_alignments.output
    output:
        fasta="results/supermatrix/supermatrix.{alignment_type}.fa",
        partition="results/supermatrix/supermatrix.{alignment_type}.partition",
        occupancy="results/supermatrix/supermatrix.{alignment_type}.occupancy",
    conda:
        ENV_DIR / "phykit.yaml"
    # bibs:
    #     "../bibs/phykit.bib"
    log:
        LOG_DIR / "supermatrix/supermatrix.{alignment_type}.log"
    shell:
        """
        phykit create_concatenation_matrix --alignment {input} --prefix results/supermatrix/supermatrix.{wildcards.alignment_type} 2>&1 | tee {log}
        """


rule supermatrix_alignment_summary:
    """
    Summarizes the supermatrix alignment using BioKIT

    https://jlsteenwyk.com/BioKIT/usage/index.html#alignment-summary
    https://jlsteenwyk.com/tutorials/phylogenomics_made_easy.html
    """
    input:
        rules.concatenate_alignments.output.fasta
    output:
        "results/supermatrix/alignment_summary.{alignment_type}.txt"
    conda:
        ENV_DIR / "biokit.yaml"
    # bibs:
    #     "../bibs/biokit.bib",
    log:
        LOG_DIR / "supermatrix/alignment_summary.{alignment_type}.log"
    shell:
        "{{ biokit alignment_summary {input} > {output} ; }} 2>&1 | tee {log}"


supermatrix_outgroup = config.get("supermatrix_outgroup", SUPERMATRIX_OUTGROUP_DEFAULT)

rule supermatrix_iqtree:
    """
    Use IQTREE on the supermatrix.
    """
    input:
        rules.concatenate_alignments.output.fasta
    output:
        treefile="results/supermatrix/supermatrix.{alignment_type}.treefile",
        consensus_tree="results/supermatrix/supermatrix.{alignment_type}.contree",
        iqtree_report="results/supermatrix/supermatrix.{alignment_type}.iqtree",
        iqtree_log="results/supermatrix/supermatrix.{alignment_type}.log",
    conda:
        ENV_DIR / "iqtree.yaml"
    # bibs:
    #     "../bibs/iqtree2.bib",
    #     "../bibs/ultrafast-bootstrap.bib",
    #     "../bibs/modelfinder.ris",
    params:
        bootstrap_string=config.get("bootstrap_string", BOOTSTRAP_STRING_DEFAULT),
        model_string=config.get("model_string", MODEL_STRING_DEFAULT),
        supermatrix_outgroup_string=f"-o {supermatrix_outgroup}" if supermatrix_outgroup else "",
    shell:
        """
        iqtree2 -s {input} \
            {params.bootstrap_string} \
            {params.model_string} \
            {params.supermatrix_outgroup_string} \
            -nt {threads} \
            -redo \
            -pre "results/supermatrix/supermatrix.{wildcards.alignment_type}"
        """

rule supermatrix_ascii:
    """
    Displays the tree in ASCII format.
    """
    input:
        rules.supermatrix_iqtree.output.treefile
    output:
        "results/supermatrix/supermatrix_tree_ascii.{alignment_type}.txt"
    conda:
        ENV_DIR / "phykit.yaml"
    # bibs:
    #     "../bibs/phykit.bib",
    shell:
        "phykit print_tree {input} > {output}"


rule supermatrix_tree_render:
    """
    Renders the supermatrix tree in SVG and PNG formats.
    """
    input:
        rules.supermatrix_iqtree.output.treefile
    output:
        svg="results/supermatrix/supermatrix_tree_render.{alignment_type}.svg",
        png="results/supermatrix/supermatrix_tree_render.{alignment_type}.png"
    conda:
        ENV_DIR / "toytree.yaml"
    # bibs:
    #     "../bibs/toytree.bib",
    shell:
        "python {SCRIPT_DIR}/render_tree.py {input} --svg {output.svg} --png {output.png}"


rule supermatrix_consensus_tree_render:
    """
    Renders the consensus supermatrix tree in SVG and PNG formats.
    """
    input:
        rules.supermatrix_iqtree.output.consensus_tree
    output:
        svg="results/supermatrix/supermatrix_consensus_tree_render.{alignment_type}.svg",
        png="results/supermatrix/supermatrix_consensus_tree_render.{alignment_type}.png"
    conda:
        ENV_DIR / "toytree.yaml"
    # bibs:
    #     "../bibs/toytree.bib",
    shell:
        "python {SCRIPT_DIR}/render_tree.py {input} --svg {output.svg} --png {output.png}"



def list_gene_trees(wildcards, extension="treefile"):
    """
    Returns a list of the treefiles for all the genes.
    """
    alignments = list_alignments(wildcards)

    gene_trees = []
    for alignment in alignments:
        alignment = Path(alignment)
        og = alignment.name.split(".")[0]
        gene_trees.append(f"results/gene_tree/{og}/{og}.{alignment_type}.{extension}")

    return gene_trees


rule create_astral_input:
    """
    Concatenate single-gene trees into one file.
    """
    input:
        list_gene_trees
    output:
        f"results/supertree/astral_input.{alignment_type}.trees"
    shell:
        """
        cat {input} > {output}
        """


rule astral:
    """
    Use ASTRAL to infer a coalescence-based tree.
    """
    input:
        rules.create_astral_input.output
    output:
        f"results/supertree/supertree.{alignment_type}.tre"
    conda:
        "../envs/astral.yaml"
    bibs:
        "../bibs/astral-iii.ris",
    log:
        "logs/supertree/astral.log"
    shell:
        """
        java -jar $CONDA_PREFIX/share/astral-tree-5.7.8-0/astral.5.7.8.jar -i {input} -o {output}
        """


rule supertree_ascii:
    """
    Displays the supertree in ASCII format.
    """
    input:
        rules.astral.output
    output:
        f"results/supertree/supertree_ascii.{alignment_type}.txt"
    conda:
        "../envs/phykit.yaml"
    bibs:
        "../bibs/phykit.bib",
    log:
        "logs/supertree/print_ascii_tree.log"
    shell:
        "phykit print_tree {input} > {output}"


rule supertree_render:
    """
    Renders the supertree in SVG and PNG formats.
    """
    input:
        rules.astral.output
    output:
        svg=f"results/supertree/supertree_render.{alignment_type}.svg",
        png=f"results/supertree/supertree_render.{alignment_type}.png"
    conda:
        "../envs/toytree.yaml"
    bibs:
        "../bibs/toytree.bib",
    log:
        "logs/supertree/supertree_render.log"
    shell:
        "python {SCRIPT_DIR}/render_tree.py {input} --svg {output.svg} --png {output.png}"


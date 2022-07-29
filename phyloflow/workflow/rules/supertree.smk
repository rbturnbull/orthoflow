def get_gene_trees(wildcards):
    alignments = list_alignments(wildcards)

    gene_trees = []
    for alignment in alignments:
        alignment = Path(alignment)
        og = alignment.name.split(".")[0]
        gene_trees.append(f"results/gene_tree/{og}/{og}.treefile")

    return gene_trees

rule create_astral_input:
    """
    Concatenate single-gene trees into one file.
    """
    input:
        get_gene_trees
    output:
        "results/supertree/astral_input.trees"
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
        report("results/supertree/supertree.tre", category="Supertree"),
    conda:
        "../envs/astral.yaml"
    bibs:
        "../bibs/astral-iii.ris",
    log:
        "logs/supertree/astral.log"
    shell:
        """
        java -jar $(find . -name astral.5.7.8.jar) -i {input} -o {output}
        """

rule supertree_ascii:
    """
    Displays the supertree in ASCII format.
    """
    input:
        rules.astral.output
    output:
        report("results/supertree/supertree_ascii.txt", category="Supertree"),
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
    Renders the tree in SVG format.
    """
    input:
        rules.astral.output
    output:
        svg=report("results/supertree/supertree_render.svg", category="Supertree"),
        html=report("results/supertree/supertree_render.html", category="Supertree"),
        png=report("results/supertree/supertree_render.png", category="Supertree"),
    conda:
        "../envs/toytree.yaml"
    bibs:
        "../bibs/toytree.bib",
    log:
        "logs/supertree/supertree_render.log"
    shell:
        "python {SCRIPT_DIR}/render_tree.py {input} --svg {output.svg} --png {output.png} --html {output.html}"


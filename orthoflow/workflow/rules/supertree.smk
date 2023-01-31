

def list_gene_tree_files(wildcards, extension):
    alignments = get_alignments(wildcards)

    gene_trees = []
    for alignment in alignments:
        alignment = Path(alignment)
        og = alignment.name.split(".")[0]
        gene_trees.append(f"results/gene_tree/{og}/{og}.{alignment_type}.{extension}")

    return gene_trees


def list_gene_trees(wildcards):
    """
    Returns a list of the treefiles for all the genes.
    """
    return list_gene_tree_files(wildcards, extension="treefile")


rule create_astral_input:
    """
    Concatenate single-gene trees into one file.
    """
    input:
        list_gene_trees
    output:
        f"results/supertree/astral_input.{alignment_type}.trees"
    log:
        LOG_DIR / "supertree/create_astral_input.log"
    shell:
        """
        echo {input} &> {log}
        {{ cat {input} > {output} ; }} &> {log}
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
        ENV_DIR / "astral.yaml"
    bibs:
        "../bibs/astral-iii.ris",
    log:
        "logs/supertree/astral.log"
    shell:
        """
        java -jar $CONDA_PREFIX/share/astral-tree-5.7.8-0/astral.5.7.8.jar -i {input} -o {output} &> {log}
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
        ENV_DIR / "phykit.yaml"
    bibs:
        "../bibs/phykit.bib",
    log:
        "logs/supertree/print_ascii_tree.log"
    shell:
        "{{ phykit print_tree {input} > {output} ; }} &> {log}"


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
        ENV_DIR / "toytree.yaml"
    bibs:
        "../bibs/toytree.bib",
    log:
        "logs/supertree/supertree_render.log"
    shell:
        "python {SCRIPT_DIR}/render_tree.py {input} --svg {output.svg} --png {output.png} &> {log}"


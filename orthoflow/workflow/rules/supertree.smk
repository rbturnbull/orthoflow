

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


rule create_astral_input:
    """
    Concatenate single-gene trees into one file.
    """
    input:
        list_gene_trees
    output:
        "results/supertree/astral_input.{alignment_type}.trees"
    log:
        LOG_DIR / "supertree/create_astral_input.{alignment_type}.log"
    shell:
        """
        echo {input} |& tee {log}
        {{ cat {input} > {output} ; }} |& tee {log}
        """


rule astral:
    """
    Use ASTRAL to infer a coalescence-based tree.
    """
    input:
        rules.create_astral_input.output
    output:
        "results/supertree/supertree.{alignment_type}.tre"
    conda:
        ENV_DIR / "astral.yaml"
    # bibs:
    #     "../bibs/astral-iii.ris",
    log:
        LOG_DIR / "supertree/astral.{alignment_type}.log"
    shell:
        """
        java -jar $CONDA_PREFIX/share/astral-tree-5.7.8-0/astral.5.7.8.jar -i {input} -o {output} |& tee {log}
        """


rule supertree_ascii:
    """
    Displays the supertree in ASCII format.
    """
    input:
        rules.astral.output
    output:
        "results/supertree/supertree_ascii.{alignment_type}.txt"
    conda:
        ENV_DIR / "phykit.yaml"
    # bibs:
    #     "../bibs/phykit.bib",
    log:
        LOG_DIR / "supertree/print_ascii_tree.{alignment_type}.log"
    shell:
        "{{ phykit print_tree {input} > {output} ; }} |& tee {log}"


rule supertree_render:
    """
    Renders the supertree in SVG and PNG formats.
    """
    input:
        rules.astral.output
    output:
        svg="results/supertree/supertree_render.{alignment_type}.svg",
        png="results/supertree/supertree_render.{alignment_type}.png"
    conda:
        ENV_DIR / "toytree.yaml"
    # bibs:
    #     "../bibs/toytree.bib",
    log:
        LOG_DIR / "supertree/supertree_render.{alignment_type}.log"
    shell:
        "python {SCRIPT_DIR}/render_tree.py {input} --svg {output.svg} --png {output.png} |& tee {log}"


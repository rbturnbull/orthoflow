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
        report("results/supertree/supertree.tre"),
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






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
        echo {input} 2>&1 | tee {log}
        {{ echo {input} | xargs cat > {output} ; }} 2>&1 | tee {log}
        """


rule astral:
    """
    Use ASTRAL to infer a coalescence-based tree.
    """
    input:
        rules.create_astral_input.output
    output:
        "results/supertree/supertree.{alignment_type}.treefile"
    conda:
        ENV_DIR / "astral.yaml"
    # bibs:
    #     "../bibs/astral-iii.ris",
    log:
        LOG_DIR / "supertree/astral.{alignment_type}.log"
    shell:
        """
        ASTRAL=$(find $CONDA_PREFIX -name 'astral.*.jar')
        java -jar $ASTRAL -i {input} -o {output} 2>&1 | tee {log}
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
        "{{ phykit print_tree {input} > {output} ; }} 2>&1 | tee {log}"


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
        "python {SCRIPT_DIR}/render_tree.py {input} --svg {output.svg} --png {output.png} 2>&1 | tee {log}"


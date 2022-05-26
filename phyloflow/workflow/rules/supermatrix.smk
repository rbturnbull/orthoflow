rule list_alignments:
    """
    List alignments.
    """
    input:
        expand("output/{og}.trID.aln.fa",og=ogs)
    output:
        "output/phykit_concat/files_to_concatenate.txt"
    shell:
        "ls -1 output/*.trID.aln.fa > {output}"

rule concatenate_alignments:
    """
    Concatenate alignments.
    """
    input:
        "output/phykit_concat/files_to_concatenate.txt"
    output:
        "output/phykit_concat/supermatrix.fa"
    params:
        prefix = lambda wildcards, output: str(output).replace(".fa", "")
    conda:
        "../envs/phykit.yaml"
    log:
        "logs/phykit_concat/supermatrix.log"
    shell:
        "phykit create_concat -a {input} -p {params.prefix} >> {log}"

rule iqtree_supermatrix:
    """
    IQTREE supermatrix.
    """
    input:
        "output/phykit_concat/supermatrix.fa"
    output:
        "output/iqtree_supermatrix/supermatrix.treefile"
    params:
        prefix = lambda wildcards, output: str(output).replace(".treefile", "")
    threads: workflow.cores
    conda:
        ""
    log:
        "logs/iqtree_supermatrix/iqtree.log"
    shell:
        "iqtree -s {input} --prefix {params.prefix} -T AUTO -ntmax {threads}"
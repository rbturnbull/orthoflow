

rule summarize_information_content:
    """
    """
    input:
        genetree_iqtree_reports=partial(list_gene_tree_files, extension="iqtree"),
        report_warning=rules.report_taxa_presence.output,
    output:
        csv="results/summary/information_content.{alignment_type}.csv",
        plot=report("results/summary/information_content.{alignment_type}.svg", category="Summary"),
    conda:
        "../envs/summary.yaml"
    log:
        LOG_DIR / "summary/summarize_information_content.{alignment_type}.log",
    shell:
        """
        python {SCRIPT_DIR}/summarize_information_content.py \
            {input.genetree_iqtree_reports} \
            {output.csv} \
            {output.plot} &> {log}
        """

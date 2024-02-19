

rule summarize_information_content:
    """
    """
    input:
        genetree_iqtree_reports=partial(list_gene_tree_files, extension="iqtree"),
        report_warning=rules.report_taxa_presence.output,
    output:
        csv="results/summary/information_content.{alignment_type}.csv",
        plot=report("results/summary/information_content.{alignment_type}.svg", category="Summary"),
        model_plot_html=report("results/summary/model.{alignment_type}.html", category="Summary"),
        model_plot_image=report("results/summary/model.{alignment_type}.pdf", category="Summary"),
        state_frequencies_plot_html=report("results/summary/state_frequencies.{alignment_type}.html", category="Summary"),
        state_frequencies_plot_image=report("results/summary/state_frequencies.{alignment_type}.pdf", category="Summary"),
    conda:
        "../envs/summary.yaml"
    log:
        LOG_DIR / "summary/summarize_information_content.{alignment_type}.log",
    shell:
        """
        python {SCRIPT_DIR}/summarize_information_content.py \
            {input.genetree_iqtree_reports} \
            {output.csv} \
            {output.plot} \
            {output.model_plot_html} \
            {output.model_plot_image} \
            {output.state_frequencies_plot_html} \
            {output.state_frequencies_plot_image} |& tee {log}
        """

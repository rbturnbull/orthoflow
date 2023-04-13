

rule summarize_information_content:
    """
    """
    input:
        alignments=rules.list_alignments.output,
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
            {input.alignments} \
            {output.csv} \
            {output.plot} &> {log}
        """

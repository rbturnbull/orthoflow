

rule summarize_information_content:
    """
    """
    input:
        alignments=rules.list_alignments.output
    output:
        tsv="results/summary/information_content.tsv",
        plot=report("results/summary/information_content.svg", category="Summary"),
    conda:
        "../envs/summary.yaml"
    shell:
        """
        python {SCRIPT_DIR}/summarize_information_content.py \
            {input.alignments} \
            {output.tsv} \
            {output.plot}
        """

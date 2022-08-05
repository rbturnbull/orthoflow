

rule report:
    input:
        supermatrix_render_svg=rules.supermatrix_render.output.svg,
        supermatrix_alignment_summary=rules.supermatrix_alignment_summary.output
    output:
        "results/report.html"
    conda:
        "../envs/jinja.yaml"
    shell:
        """
        python {SCRIPT_DIR}/report.py \
            --supermatrix-render-svg {input.supermatrix_render_svg} \
            --supermatrix-alignment-summary {input.supermatrix_alignment_summary} \
            --output {output}
        """
        
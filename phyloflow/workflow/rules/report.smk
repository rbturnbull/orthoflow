from pathlib import Path
import jinja2
import typer


use_supermatrix = config.get("supermatrix", True)
use_supertree = config.get("supertree", False)
use_orthofisher = config.get('use_orthofisher', USE_ORTHOFISHER_DEFAULT)


rule report:
    input:
        orthofinder_scogs=list_orthofinder_scogs,
        orthosnap_snap_ogs=list_orthosnap_snap_ogs,
        supermatrix_render_svg=rules.supermatrix_render.output.svg if use_supermatrix else ".",
        supermatrix_alignment_summary=rules.supermatrix_alignment_summary.output  if use_supermatrix else ".",
        list_alignments=rules.list_alignments.output,
        summary_plot=rules.summarize_information_content.output.plot,
        supertree_render_svg=rules.supertree_render.output.svg if use_supertree else ".",
        supertree_ascii=rules.supertree_ascii.output if use_supertree else ".",
    output:
        "results/report.html"
    run:
        report_dir = SNAKE_DIR/"report"
        print('report_dir', report_dir)
        loader = jinja2.FileSystemLoader(report_dir)
        env = jinja2.Environment(
            loader=loader,
            autoescape=jinja2.select_autoescape()
        )
        def include_file(name):
            print('include', name)
            if name:
                return Path(str(name)).read_text()
            return ""

        env.globals['include_file'] = include_file

        template = env.get_template("report-template.html")
        result = template.render(
            input=input,
            use_orthofisher=use_orthofisher,
            use_supertree=use_supertree,
            use_supermatrix=use_supermatrix,
            bibliography=workflow.persistence.dag.bibliography(output_backend="html"),
            bibtex=workflow.persistence.dag.bibliography(format="bibtex"),
        )

        with open(str(output), 'w') as f:
            print(f"Writing result to {output}")
            f.write(result)        
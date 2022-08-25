from pathlib import Path
import jinja2
import typer
from functools import partial


use_supermatrix = config.get("supermatrix", True)
use_supertree = config.get("supertree", False)
use_orthofisher = config.get('use_orthofisher', USE_ORTHOFISHER_DEFAULT)


rule report:
    input:
        orthofinder_scogs=list_orthofinder_scogs,
        orthosnap_snap_ogs=list_orthosnap_snap_ogs,
        orthofinder_report_components=rules.orthofinder_report_components.output,
        supermatrix_tree_svg=rules.supermatrix_tree_render.output.svg if use_supermatrix else ".",
        supermatrix_consensus_tree_svg=rules.supermatrix_consensus_tree_render.output.svg if use_supermatrix else ".",
        supermatrix_alignment_summary=rules.supermatrix_alignment_summary.output  if use_supermatrix else ".",
        supermatrix_iqtree_report=rules.supermatrix_iqtree.output.iqtree_report  if use_supermatrix else ".",
        supermatrix_iqtree_log=rules.supermatrix_iqtree.output.iqtree_log  if use_supermatrix else ".",
        list_alignments=rules.list_alignments.output,
        summary_plot=rules.summarize_information_content.output.plot,
        supertree_render_svg=rules.supertree_render.output.svg if use_supertree else ".",
        supertree_ascii=rules.supertree_ascii.output if use_supertree else ".",
        genetree_iqtree_reports=partial(list_gene_trees, extension="iqtree") if use_supertree else ".",
        genetree_iqtree_logs=partial(list_gene_trees, extension="log") if use_supertree else ".",
        genetree_svgs=partial(list_gene_trees, extension="tree.svg") if use_supertree else ".",
        genetree_consensus_svgs=partial(list_gene_trees, extension="consensus-tree.svg") if use_supertree else ".",
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
        def include_file(*args):
            args = [str(arg) for arg in args]
            path = Path(*args)
            if path:
                return path.read_text()
            return ""

        def pandas_to_bootstrap(df, output:Path = None):
            """
            Adapted from https://stackoverflow.com/a/62153724
            """
            dict_data = [df.to_dict(), df.to_dict('index')]

            html = '<div class="table-responsive"><table class="table table-sm table-striped table-hover table-sm align-middle"><tr class="table-primary">'

            column_names = [df.index.name] + list(dict_data[0].keys())
            for key in column_names:
                html += f'<th class="header" scope="col">{key}</th>'

            html += '</tr>'

            for key in dict_data[1].keys():
                html += f'<tr><th class="index " scope="row">{key}</th>'
                for subkey in dict_data[1][key]:
                    cell_text = dict_data[1][key][subkey] if not pd.isna(dict_data[1][key][subkey]) else "—"
                    html += f'<td>{cell_text}</td>'

            html += '</tr></table></div>'
            if output:
                output.parent.mkdir(exist_ok=True, parents=True)
                output.write_text(html)

            return html            
        
        def parent_name(path):
            return Path(path).parent.name

        env.globals['include_file'] = include_file
        env.globals['parent_name'] = parent_name
        env.globals['pandas_to_bootstrap'] = pandas_to_bootstrap
        env.globals.update(zip=zip)

        template = env.get_template("report-template.html")
        result = template.render(
            input=input,
            input_csv=input_csv,
            use_orthofisher=use_orthofisher,
            use_supertree=use_supertree,
            use_supermatrix=use_supermatrix,
            bibliography=workflow.persistence.dag.bibliography(output_backend="html"),
            bibtex=workflow.persistence.dag.bibliography(format="bibtex"),
        )

        with open(str(output), 'w') as f:
            print(f"Writing result to {output}")
            f.write(result)        
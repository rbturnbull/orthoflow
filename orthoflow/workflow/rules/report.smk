from pathlib import Path
import jinja2
import typer
from functools import partial
import pydot


use_supermatrix = config.get("supermatrix", True)
use_supertree = config.get("supertree", False)
use_orthofisher = config.get('use_orthofisher', USE_ORTHOFISHER_DEFAULT)
gene_tree_summary = config.get('gene_tree_summary', True)

rule report:
    """
    Draws together the output of the workflow and presents the results in a stand-alone HTML file.

    This serves as the endpoint of the DAG for Snakemake if no targets are explicitly specified.
    """
    input:
        input_sources_csv=rules.input_sources_csv.output[0],
        # Orthofinder
        orthofinder_scogs=rules.orthogroup_classification.output.scogs if not use_orthofisher else ".",
        orthofinder_report_components=rules.orthofinder_report_components.output if not use_orthofisher else ".",
        orthosnap_snap_ogs=rules.write_snap_ogs_list.output.snap_ogs if not use_orthofisher else ".",
        orthogroup_classification_histogram=rules.orthogroup_classification.output.histogram if not use_orthofisher else ".",
        # Alignment
        list_alignments=rules.list_alignments.output,
        # Gene Tree
        summary_plot=rules.gene_tree_summary.output.plot if use_supertree else ".",
        model_plot_html=rules.gene_tree_summary.output.model_plot_html if use_supertree else ".",
        state_frequencies_plot_html=rules.gene_tree_summary.output.state_frequencies_plot_html if use_supertree else ".",
        # Supertree
        supertree=rules.astral.output if use_supertree else ".",
        supertree_render_svg=rules.supertree_render.output.svg if use_supertree else ".",
        supertree_ascii=rules.supertree_ascii.output if use_supertree else ".",
        # Supermatrix
        supermatrix_tree_svg=rules.supermatrix_tree_render.output.svg if use_supermatrix else ".",
        supermatrix_consensus_tree_svg=rules.supermatrix_consensus_tree_render.output.svg if use_supermatrix else ".",
        supermatrix_alignment_summary=rules.supermatrix_alignment_summary.output  if use_supermatrix else ".",
        supermatrix_iqtree_report=rules.supermatrix_iqtree.output.iqtree_report  if use_supermatrix else ".",
        supermatrix_iqtree_log=rules.supermatrix_iqtree.output.iqtree_log  if use_supermatrix else ".",
        # Warnings
        missing_taxa=rules.missing_taxa.output,
    output:
        "results/report.{alignment_type}.html"
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
            if path and not path.is_dir():
                return path.read_text()
            return ""

        def pandas_to_bootstrap(df, output:Path = None):
            """
            Adapted from https://stackoverflow.com/a/62153724
            """
            if isinstance(df, str):
                df = pd.read_csv(df)
                df.index.name = "Index"

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

        warnings = []
        for warnings_file in WARNINGS_DIR.glob("*.txt"):
            warning = warnings_file.read_text()
            if warning:
                warnings.append(warning)
        if len(warnings) == 0:
            warnings.append("No warnings found.")

        try:        
            result = template.render(
                input=input,
                use_orthofisher=use_orthofisher,
                use_supertree=use_supertree,
                use_supermatrix=use_supermatrix,
                bibliography=(report_dir/"bibliography-content.html").read_text(),
                bibtex=(report_dir/"bibliography-content.bib").read_text(),
                # bibliography=workflow.persistence.dag.bibliography(output_backend="html"),
                # bibtex=workflow.persistence.dag.bibliography(format="bibtex"),
                warnings=warnings,
            )
            with open(str(output), 'w') as f:
                print(f"Writing result to {output}")
                f.write(result)        
        except Exception as err:
            print_warning(f"Failed to render report:\n{err}")
            


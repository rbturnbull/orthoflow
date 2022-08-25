from pathlib import Path
import pandas as pd
import typer
from rich.progress import track


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


def orthofinder_report_components(
    orthofinder_dir:Path, 
    report_dir:Path, 
):

    orthogroups = pd.read_csv(orthofinder_dir/"Orthogroups/Orthogroups.tsv", sep="\t").set_index('Orthogroup')
    pandas_to_bootstrap(orthogroups, report_dir/"Orthogroups.html")
    
    

  

if __name__ == '__main__':
    typer.run(orthofinder_report_components)
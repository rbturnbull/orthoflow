#!/usr/bin/env python3
from pathlib import Path
import pandas as pd
import typer


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

    pandas_to_bootstrap(
        pd.read_csv(orthofinder_dir/"Orthogroups/Orthogroups.tsv", sep="\t").set_index('Orthogroup'), 
        report_dir/"Orthogroups.html"
    )
    pandas_to_bootstrap(
        pd.read_csv(orthofinder_dir/"Orthogroups/Orthogroups_UnassignedGenes.tsv", sep="\t").set_index('Orthogroup'), 
        report_dir/"Orthogroups_UnassignedGenes.html"
    )

    df = pd.read_csv(orthofinder_dir/"Comparative_Genomics_Statistics/Orthogroups_SpeciesOverlaps.tsv", sep="\t")
    df = df.rename(columns={"Unnamed: 0":"Input"}).set_index('Input')
    pandas_to_bootstrap(
        df, 
        report_dir/"Orthogroups_SpeciesOverlaps.html"
    )

    # Get OG totals stats
    # no longer applicable since we are not using the full orthofinder workflow
    # df = pd.read_csv(orthofinder_dir/"Comparative_Genomics_Statistics/OrthologuesStats_Totals.tsv", sep="\t")
    # df = df.rename(columns={"Unnamed: 0":"Input"}).set_index('Input')
    # pandas_to_bootstrap(
    #     df, 
    #     report_dir/"OrthologuesStats_Totals.html"
    # )

    

  

if __name__ == '__main__':
    typer.run(orthofinder_report_components)
#!/usr/bin/env python3
import re
from pathlib import Path
import pandas as pd
from io import StringIO
import plotly.express as px
import typer

import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from figures import format_fig


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
    orthofinder_dir = Path(orthofinder_dir)
    report_dir = Path(report_dir)

    # Overall Statistics
    overall = (orthofinder_dir/"Comparative_Genomics_Statistics/Statistics_Overall.tsv").read_text()
    components = overall.split("\n\n")
    if len(components) > 0:
        name_value = pd.read_csv(StringIO(components[0]), sep="\t", header=None, names=["Name", "Value"], index_col=0)
        pandas_to_bootstrap(name_value, report_dir/"overall.html")
        
    if len(components) > 1:
        genes_per_species = pd.read_csv(StringIO(components[1]), sep="\t")
        pandas_to_bootstrap(genes_per_species, report_dir/"genes_per_species.html")
        fig = format_fig(px.bar(genes_per_species, x="Average number of genes per-species in orthogroup", y="Number of orthogroups"))
        fig.write_html(report_dir/"genes_per_species_og_fig.html")
        fig = format_fig(px.bar(genes_per_species, x="Average number of genes per-species in orthogroup", y="Number of genes"))
        fig.write_html(report_dir/"genes_per_species_genes_fig.html")

    if len(components) > 2:
        number_of_species = pd.read_csv(StringIO(components[2]), sep="\t")
        fig = format_fig(px.bar(number_of_species, x="Number of species in orthogroup", y="Number of orthogroups"))
        fig.write_html(report_dir/"og_count_vs_species_count.html")


    # Statistics_PerSpecies
    per_species = (orthofinder_dir/"Comparative_Genomics_Statistics/Statistics_PerSpecies.tsv").read_text()

    per_species = re.sub(r"\n\n+", "\n\n", per_species)
    per_species_components = per_species.split("\n\n")
    if len(components) > 0:
        per_species_stats = pd.read_csv(StringIO("Stub"+per_species_components[0].replace(".renamed", "")), sep="\t", index_col=0).transpose()
        pandas_to_bootstrap(per_species_stats, report_dir/"per_species_stats.html")

    if len(per_species_components) > 1:
        number_of_ogs_per_species = pd.read_csv(StringIO(per_species_components[1]), sep="\t", index_col=0)
        number_of_ogs_per_species.columns = per_species_stats.index
        number_of_ogs_per_species_melted = number_of_ogs_per_species.transpose().melt(var_name="Number of genes per-species in orthogroup", value_name="Number of orthogroups")
        fig = px.box(number_of_ogs_per_species_melted, x='Number of genes per-species in orthogroup', y='Number of orthogroups')
        format_fig(fig)
        fig.write_html(report_dir/"og_count_vs_number_of_genes_per_species.html")

    if len(per_species_components) > 3:
        number_of_ogs_per_species = pd.read_csv(StringIO(per_species_components[3]), sep="\t", index_col=0)
        number_of_ogs_per_species.columns = per_species_stats.index
        number_of_ogs_per_species_melted = number_of_ogs_per_species.transpose().melt(var_name="Number of genes per-species in orthogroup", value_name="Number of genes")
        fig = px.box(number_of_ogs_per_species_melted, x='Number of genes per-species in orthogroup', y='Number of genes')
        format_fig(fig)
        fig.write_html(report_dir/"gene_count_vs_number_of_genes_per_species.html")

    # Orthogroups_SpeciesOverlaps
    overlaps = pd.read_csv(orthofinder_dir/"Comparative_Genomics_Statistics/Orthogroups_SpeciesOverlaps.tsv", sep="\t", index_col=0)
    columns = overlaps.columns.str.replace(".renamed", "", regex=False).str.replace(".translated", "", regex=False)
    fig = px.imshow(overlaps, labels=dict(color="Overlap"), x=columns, y=columns)
    format_fig(fig)
    fig.update_layout(width=1200, height=1200)
    fig.write_html(report_dir/"species_overlaps.html")


if __name__ == '__main__':
    typer.run(orthofinder_report_components)
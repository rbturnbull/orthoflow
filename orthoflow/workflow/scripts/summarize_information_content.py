#!/usr/bin/env python3
import re
from pathlib import Path
from typing import List
import plotly.express as px

import matplotlib.pyplot as plt
from scipy.stats import spearmanr
import seaborn as sns
import pandas as pd
import typer
from rich.progress import track


def format_fig(fig):
    """Formats a plotly figure in a nicer way."""
    fig.update_layout(
        width=1000,
        height=600,
        plot_bgcolor="white",
        title_font_color="black",
        font=dict(
            family="Linus Libertinus",        
            size=18,
            color="black",
        ),
    )
    gridcolor = "#dddddd"
    fig.update_xaxes(gridcolor=gridcolor)
    fig.update_yaxes(gridcolor=gridcolor)

    fig.update_xaxes(showline=True, linewidth=1, linecolor='black', mirror=True, ticks='outside', zeroline=True, zerolinewidth=1, zerolinecolor='black')
    fig.update_yaxes(showline=True, linewidth=1, linecolor='black', mirror=True, ticks='outside', zeroline=True, zerolinewidth=1, zerolinecolor='black')

    return fig


def summarize_information_content(
    genetree_iqtree_reports:List[Path], 
    output_csv:Path, 
    output_plot:Path,
    model_plot_html:Path,    
    model_plot_image:Path,
    state_frequencies_plot_html:Path,
    state_frequencies_plot_image:Path,
):
    # initialize arrays to hold summary information content
    alignment_array = []
    model_array = []
    state_frequencies_array = []
    for gene_tree_iqtree_report_path in genetree_iqtree_reports:
        gene_tree_iqtree_report_path = Path(gene_tree_iqtree_report_path)
        gene_tree_iqtree_report = gene_tree_iqtree_report_path.read_text()
        name = gene_tree_iqtree_report_path.with_suffix('').name

        def match_pattern(pattern, metric_name, array):
            if isinstance(metric_name, str):
                metric_name = [metric_name]

            match = re.search(pattern, gene_tree_iqtree_report)
            if match:
                for i, metric in enumerate(metric_name):
                    array.append([metric, match.group(i+1), name])

        match_pattern(r"Input data: (\d+) sequences with (\d+) ", ["number_of_sequences", "alignment_length"], alignment_array)
        match_pattern(r"Number of constant sites: (\d+) ", "constant_sites", alignment_array)
        match_pattern(r"Number of parsimony informative sites: (\d+)\n", "parsimony_informative_sites", alignment_array)
        match_pattern(r"Number of distinct site patterns: (\d+)\n", "distinct_site_patterns", alignment_array)

        match_pattern(r"Model of substitution: (.+)\n", "best_fit_model", model_array)

        for match in re.findall(r"pi\((.+)\) = (\d*\.?\d+)", gene_tree_iqtree_report):
            state_frequencies_array.append([match[0], float(match[1]), name])

    # write out dataframes of information content
    df = write_df_to_csv_file(
        alignment_array, 
        output_csv,
    )

    # create plot
    generate_pairplot(
        df,
        "Information content",
        output_plot,
    )

    generate_model_plot(model_array, model_plot_html, model_plot_image)
    generate_state_frequencies_plot(state_frequencies_array, state_frequencies_plot_html, state_frequencies_plot_image)


def generate_model_plot(model_array, model_plot_html:Path, model_plot_image:Path, max_models=10):
    model_df = pd.DataFrame(model_array, columns = ['metric', 'value', 'alignment'])

    value_counts = model_df['value'].value_counts()
    if len(value_counts) > max_models:
        other_count = value_counts[max_models:].sum()
        value_counts = value_counts[:max_models]
        value_counts['Other'] = other_count

    fig = px.histogram(
        x=value_counts.index, 
        y=value_counts, 
        title="Best fit model",
    )
    format_fig(fig)
    fig.update_xaxes(title_text="Model")
    fig.update_yaxes(title_text="Count")
    fig.update_traces(marker_color="#003d86")
    fig.write_html(model_plot_html)
    fig.write_image(model_plot_image)
    return fig


def generate_state_frequencies_plot(state_frequencies_array, state_frequencies_plot_html:Path, state_frequencies_plot_image:Path):
    frequency_df = pd.DataFrame(state_frequencies_array, columns = ['Character', 'Frequency', 'alignment'])
    fig = px.box(
        frequency_df, 
        x="Character", 
        y="Frequency", 
        title="State Frequencies",
    )
    format_fig(fig)
    fig.update_traces(marker_color="#003d86")
    fig.write_html(state_frequencies_plot_html)
    fig.write_image(state_frequencies_plot_image)
    return fig


def generate_pairplot(
    df, # pd dataframe
    plot_title: str,
    output_path: Path,
):
    # convert from long to wide format
    df = df.pivot(index='alignment', columns='metric', values='value').reset_index().rename_axis(None, axis=1)
    # replace column names
    df = df.astype(
        {
            "number_of_sequences" : "int",
            "alignment_length" : "int",
            "constant_sites" : "int",
            "parsimony_informative_sites" : "int",
            "distinct_site_patterns" : "int",
        }
    )

    df = df.rename(columns={column:column.replace("_", " ").title() for column in df.columns})
    
    df.drop('Alignment', axis=1)

    # define custom parameters of seaborn plot
    custom_params = {
        "axes.spines.right": False,
        "axes.spines.top": False
    }
    sns.set_theme(style="ticks", rc=custom_params)
    info_content_plot = sns.pairplot(
        df,
        kind="reg",
        plot_kws={
            "line_kws" : {"color":"#5C5C5C"},
            "scatter_kws" : {"alpha":0.5, "color":"#003d86"}
            },
        diag_kws={'color': '#003d86'}
    )
    info_content_plot.map_lower(corrfunc)
    info_content_plot.map_upper(corrfunc)
    info_content_plot.fig.suptitle(plot_title, y=1.01)
    plt.savefig(
        output_path,
        bbox_inches = "tight"
    )


def write_df_to_csv_file(
    df: list, 
    output_name: str
):

    df = pd.DataFrame(df, columns = ['metric', 'value', 'alignment'])
    df.to_csv(output_name, index=False, header=True, sep=",")

    return df


def corrfunc(
    x,
    y,
    **kws
):
    (r, p) = spearmanr(x, y)
    ax = plt.gca()
    ax.annotate("r = {:.2f} ".format(r),
                xy=(.05, 0.95), xycoords=ax.transAxes)
    ax.annotate(" p = {:.3f}".format(p),
                xy=(.35, 0.95), xycoords=ax.transAxes)


if __name__ == '__main__':
    typer.run(summarize_information_content)
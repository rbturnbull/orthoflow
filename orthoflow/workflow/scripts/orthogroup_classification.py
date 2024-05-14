#!/usr/bin/env python3

import re
from enum import Enum
from pathlib import Path
from collections import Counter
import typer
import pandas as pd

from joblib import Parallel, delayed
from rich.console import Console
from dataclasses import dataclass
import plotly.express as px
import plotly.io as pio   

pio.kaleido.scope.mathjax = None

console = Console()

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


@dataclass
class OGSummary():
    single:bool
    taxa_count:int
    seq_count:int


def summarize_orthogroup(fasta_file: Path) -> OGSummary:
    taxon_counter = Counter()

    pattern = re.compile(r"^>(.*?)\|.*$")
    with open(fasta_file, "r") as f:
        for line in f:
            match = pattern.match(line)
            if match:
                taxon = match.group(1).strip()
                taxon_counter.update([taxon])

    # Check to see the total number of sequences reaches the minimum
    seq_count = sum(taxon_counter.values())
    taxa_count = len(taxon_counter)

    # Get the number of most frequently occuring taxon
    # If it is just one then all taxa have only one copy and this is a single-copy OG
    # If it is higher than one then this is a multi-copy OG
    _ , top_count = taxon_counter.most_common(1)[0]
    single = (top_count == 1)

    return OGSummary(
        single=single,
        seq_count=seq_count,
        taxa_count=taxa_count,
    )


def classify_all_orthogroups(
    directory: Path = typer.Argument(...,help="The directory of orthogroup sequences. Assumes all files have suffix .fa"),
    mcogs:Path = typer.Option(...,help="A text file to save a list of multi-copy orthogroups."),
    scogs:Path = typer.Option(...,help="A text file to save a list of single-copy orthogroups."),
    csv:Path = typer.Option(...,help="The path to save a CSV of the classifications."),
    histogram:Path = typer.Option(...,help="The path to save a histogram."),
    min_seqs:int = typer.Option(...,help="The minimum number of sequences in an orthogroup."),
    min_taxa:int = typer.Option(...,help="The minimum number of taxa in an orthogroup."),
    n_jobs:int = typer.Option(-1, help="The number of jobs to run in parallel. The default of -1 means that all CPUs are used."),
):  
    files = sorted(list(directory.glob("*.fa")))
    results = Parallel(n_jobs=n_jobs)(delayed(summarize_orthogroup)(file) for file in files)

    data = []
    with open(mcogs, "w") as mcogs_stream, open(scogs, "w") as scogs_stream:
        for file, result in zip(files, results):
            if result.taxa_count < min_taxa:
                style = "dark_red"
                classification = "BELOW MIN TAXA"
            elif result.seq_count < min_seqs:
                style = "red"
                classification = "BELOW MIN SEQS"
            elif result.single:
                print(file, file=scogs_stream)
                style = "green"
                classification = "SCOG"
            else:
                print(file, file=mcogs_stream)
                style = "purple"
                classification = "MCOG"

            console.print(f"{file} ({result.taxa_count} taxa, {result.seq_count} seqs) -> {classification}", style=style)
            data.append(dict(file=str(file), single="SCOG" if result.single else "MCOG", classification=classification, taxa_count=result.taxa_count, seq_count=result.seq_count))

    # Save CSV
    df = pd.DataFrame(data)
    csv = Path(csv)
    csv.parent.mkdir(exist_ok=True, parents=True)
    df.to_csv(csv)

    # Taxa count histogram
    fig = px.ecdf(df, x='taxa_count', color='single', ecdfnorm=None, ecdfmode="complementary")
    fig.add_shape(type="line",
        xref="x", yref="paper",
        x0=15, y0=0, x1=15, y1="1",
        line=dict(
            color="LightSeaGreen",
            width=3,
        ),
    )
    fig.add_annotation(
        xref="x", yref="paper",
        x=15, 
        yanchor="bottom",
        y="1",
                text="Min Taxa",
                showarrow=False,
                font_size=20,
    )

    format_fig(fig)
    fig.update_layout(
        xaxis_title="Number of Taxa",
        yaxis_title="Complementary Cumulative Count",
        legend_title="OG Type",
    )
    if Path(histogram).suffix == ".html":
        fig.write_html(histogram)
    else:
        fig.write_image(histogram)


if __name__ == "__main__":
    typer.run(classify_all_orthogroups)

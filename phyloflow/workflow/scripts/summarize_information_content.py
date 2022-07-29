import subprocess
from pathlib import Path

import matplotlib.pyplot as plt
from scipy.stats import spearmanr
import seaborn as sns
import pandas as pd
import typer


def summarize_information_content(
    alignment_list:Path, 
    # gene_trees_list:Path, 
    output_tsv:Path, 
    output_plot:Path
):
    with open(alignment_list) as f:
        aln_file_paths = f.readlines()

    # initialize arrays to hold summary information content
    res_arr = []

    # define the metrics to calculate
    metrics_all_aln = [
        "alignment_length",
        "relative_composition_variability",
        "parsimony_informative_sites",
        "variable_sites",
    ]

    metrics_all_tre = [
        "treeness",
        "evolutionary_rate",
        "robinson_foulds_distance",
        "bipartition_support_stats", # get mean
    ]

    # loop through files, evaluate information content, and save to arr
    # TODO: remove control that only loops through ten alignments
    for aln in aln_file_paths[:10]:
        
        for metric in metrics_all_aln:
            res_arr.append(
                eval_info_content(
                    metric,
                    aln,
                )
            )

    # write out dataframes of information content
    df = write_df_to_tsv_file(
        res_arr, 
        output_tsv,
    )

    # create plot
    generate_pairplot(
        df,
        "Information content",
        output_plot,
    )


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
            "alignment_length" : "float",
            "relative_composition_variability" : "float",
            "parsimony_informative_sites" : "float",
            "variable_sites" : "float",
        }
    )
    df = df.rename(
        columns = {
            "alignment_length" : "alignment length",
            "relative_composition_variability" : "relative composition variability",
            "parsimony_informative_sites" : "parsimony informative sites",
            "variable_sites" : "variable sites",
        }
    )
    df.drop('alignment', axis=1)

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


def write_df_to_tsv_file(
    df: list, 
    output_name: str
):

    df = pd.DataFrame(df, columns = ['metric', 'value', 'alignment'])
    df.to_csv(output_name, index=False, header=True, sep="\t")

    return df


def eval_info_content(
    metric: str,
    aln_name: str,
):
    
    metrics_with_multiple_columns = [
        "alignment_length_no_gaps",
        "parsimony_informative_sites", 
        "variable_sites"
    ]

    res_line = []
    _phykit_cmd = ['phykit', metric, str(aln_name).strip()]
    res_line.append(metric)
    # handle outputs with multiple columns otherwise take all output
    if metric in metrics_with_multiple_columns:
        res_line.append(subprocess.check_output(_phykit_cmd).splitlines()[0].decode('utf-8').split("\t")[0])
    elif metric == "pairwise_identity":
        res_line = []
        res_line.append("average_pairwise_identity")
        res_line.append(subprocess.check_output(_phykit_cmd).splitlines()[0].decode('utf-8').split(" ")[1])
    else:
        res_line.append(subprocess.check_output(_phykit_cmd).splitlines()[0].decode('utf-8'))
    res_line.append(aln_name)

    return res_line

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
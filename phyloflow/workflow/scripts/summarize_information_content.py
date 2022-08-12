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
    output_csv:Path, 
    output_plot:Path
):

    # read in file paths
    aln_file_paths = [alignment for alignment in alignment_list.read_text().split("\n") if alignment]

    # initialize arrays to hold summary information content
    res_arr = []

    # define the metrics to calculate
    metrics_all_aln = [
        "alignment_length",
        "relative_composition_variability",
        "pairwise_identity", # get mean
        "parsimony_informative_sites",
        "variable_sites",
    ]

    # metrics_all_tre = [
    #     "treeness",
    #     "robinson_foulds_distance",
    #     "bipartition_support_stats", # get mean
    # ]

    # loop through files, evaluate information content, and save to arr
    for aln in aln_file_paths:
        
        for metric in metrics_all_aln:
            res_arr.append(
                eval_info_content(
                    metric,
                    aln,
                )
            )

    # write out dataframes of information content
    df = write_df_to_csv_file(
        res_arr, 
        output_csv,
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
            "pairwise_identity" : "float",
            "parsimony_informative_sites" : "float",
            "variable_sites" : "float"
        }
    )

    df = df.rename(columns={column:column.replace("_", " ").title() for column in df.columns})
    
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


def write_df_to_csv_file(
    df: list, 
    output_name: str
):

    df = pd.DataFrame(df, columns = ['metric', 'value', 'alignment'])
    df.to_csv(output_name, index=False, header=True, sep=",")

    return df


def eval_info_content(
    metric: str,
    aln_name: str,
):

    res_line = []
    _phykit_cmd = ['phykit', metric, str(aln_name).strip()]
    res_line.append(metric)
    # handle outputs with multiple columns otherwise take all output
    if metric in ["parsimony_informative_sites", "variable_sites"]:
        res_line.append(subprocess.check_output(_phykit_cmd).splitlines()[0].decode('utf-8').split("\t")[0])
    elif metric == "pairwise_identity":
        temp_res = subprocess.check_output(_phykit_cmd).splitlines()[0].decode('utf-8')
        res_line.append(temp_res.replace("mean: ", ""))
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
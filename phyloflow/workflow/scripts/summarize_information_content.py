import os
import subprocess

import matplotlib.pyplot as plt
from scipy.stats import spearmanr
import seaborn as sns
import pandas as pd

# TODO: create snakemake rule for script

def main():
    # get alignment file paths
    alignments_path = "tests/test-data/results/alignment/"
    aa_aln_file_paths = [f for f in os.listdir(alignments_path) if f.endswith('alignment.fa')]
    nt_aln_file_paths = [f for f in os.listdir(alignments_path) if f.endswith('alignment.cds.fa')]

    # initialize arrays to hold summary information content
    aa_res_arr = []
    nt_res_arr = []

    # define the metrics to calculate
    metrics_all = [
        "alignment_length",
        "alignment_length_no_gaps",
        "pairwise_identity",
        "parsimony_informative_sites",
        "variable_sites",
    ]

    # loop through files, evaluate information content, and save to arr
    # TODO: remove control that only loops through ten alignments
    for aa_aln, nt_aln in zip(aa_aln_file_paths[:10], nt_aln_file_paths[:10]):
        
        for metric in metrics_all:
        
            aa_res_arr = eval_info_content(
                metric,
                alignments_path,
                aa_aln,
                aa_res_arr
            )

            nt_res_arr = eval_info_content(
                metric,
                alignments_path,
                nt_aln,
                nt_res_arr
            )


    # write out dataframes of information content
    aa_df = write_df_to_tsv_file(
        aa_res_arr, 
        "information_content_aa.tsv"
        )

    nt_df = write_df_to_tsv_file(
        nt_res_arr, 
        "information_content_nt.tsv"
    )

    # create plot
    generate_pairplot(
        aa_df,
        "Information content, amino acids",
        "information_content_amino_acids",
        "png"
    )

    generate_pairplot(
        nt_df,
        "Information content, nucleotides",
        "information_content_nucleotides",
        "png"
    )

def generate_pairplot(
    df, # pd dataframe
    plot_title: str,
    output_file_name: str,
    file_format: str
):
    # convert from long to wide format
    df = df.pivot(index='alignment', columns='metric', values='value').reset_index().rename_axis(None, axis=1)
    # replace column names
    df = df.astype(
        {
            "alignment_length" : "float",
            "alignment_length_no_gaps" : "float",
            "average_pairwise_identity" : "float",
            "parsimony_informative_sites" : "float",
            "variable_sites" : "float",
        }
    )
    df = df.rename(
        columns = {
            "alignment_length" : "alignment length",
            "alignment_length_no_gaps" : "alignment length, no gaps",
            "average_pairwise_identity" : "average pairwise identity",
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
        f"{output_file_name}.{file_format}",
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
    alignments_path: str,
    aln_name: str,
    res_arr: list
):
    
    metrics_with_multiple_columns = [
        "alignment_length_no_gaps",
        "parsimony_informative_sites", 
        "variable_sites"
    ]

    res_line = []
    _phykit_cmd = ['phykit', metric, str(alignments_path)+str(aln_name)]
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
    res_arr.append(res_line)

    return res_arr

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
    main()
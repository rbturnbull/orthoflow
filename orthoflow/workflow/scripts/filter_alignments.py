#!/usr/bin/env python3

from pathlib import Path
from Bio import AlignIO
from joblib import Parallel, delayed
from typing import List
import typer

app = typer.Typer()

def filter_alignment(trimmed_alignment_path:Path, untrimmed_alignment_path:Path, min_length:int, max_trimmed_proportion:float) -> bool:
    """
    Determines whether or not this trimmed alignment should be included for downstream analysis.

    Args:
        trimmed_alignment_path (Path): The path to the trimmed alignment
        untrimmed_alignment_path (Path): The path to the untrimmed alignment
        min_length (int): The minimum length that a trimmed alignment can be for it to be included in downstream analysis.
        max_trimmed_proportion (float): The maximum proportion of the untrimmed alignment 
            that the trimmed alignment can be before excluded from downstream analysis.

    Returns:
        bool: Whether or not this trimmed alignment should be included for downstream analysis.
    """
    trimmed_alignment= AlignIO.read(trimmed_alignment_path, "fasta")
    trimmed_length = trimmed_alignment.get_alignment_length()
    if trimmed_length < min_length:
        print(f"{trimmed_alignment_path} of length {trimmed_length} which is below the minimum length {min_length}")
        return False

    untrimmed_length = AlignIO.read(untrimmed_alignment_path, "fasta").get_alignment_length()
    print(trimmed_alignment_path, trimmed_length, untrimmed_length)
    if trimmed_length <= max_trimmed_proportion * untrimmed_length:
        print(f"{trimmed_alignment_path} of length {trimmed_length} which is below {max_trimmed_proportion} of the untrimmed length {untrimmed_length}")
        return False

    # Check for duplicate sequences and filter out alignments where the number of unique sequences is below four
    unique_seqs = set()
    for record in trimmed_alignment:
        unique_seqs.add(str(record.seq))
    
    if len(unique_seqs) < 4:
        print(f"{trimmed_alignment_path} has only {len(unique_seqs)} unique sequences")
        return False

    return True


@app.command()
def filter_alignments(
    trimmed_alignment_paths:List[Path], 
    untrimmed_alignment_paths:List[Path],
    min_length:int = typer.Option(...),
    max_trimmed_proportion:float = typer.Option(...),
    output_txt:Path = None,
    n_jobs:int = typer.Option(-1, help="The number of jobs to run in parallel. The default of -1 means that all CPUs are used."),
) -> List:
    """
    Returns a list of alignments which have a minimum length and the proportion of sites retained after trimming.

    Args:
        trimmed_alignment_paths (List[Path]): The list of paths to the trimmed alignments.
        untrimmed_alignment_paths (List[Path]): The list of paths to the untrimmed alignments.
        min_length (int): The minimum length that a trimmed alignment can be for it to be included in downstream analysis.
        max_trimmed_proportion (float): The maximum proportion of the untrimmed alignment 
            that the trimmed alignment can be before excluded from downstream analysis.
        output_txt: (Path): A file to save the list to.
        n_jobs (int): The number of jobs to run in parallel. The default of -1 means that all CPUs are used.

    Returns:
        List[Path]: The list of trimmed alignment paths to use for phylogenetic analysis.
    """
    keep_list = Parallel(n_jobs=n_jobs)(
        delayed(filter_alignment)(trimmed_alignment_path, untrimmed_alignment_path, min_length, max_trimmed_proportion) 
        for trimmed_alignment_path, untrimmed_alignment_path in zip(trimmed_alignment_paths, untrimmed_alignment_paths)
    )

    trimmed_to_keep = [trimmed_alignment_path for trimmed_alignment_path, keep in zip(trimmed_alignment_paths, keep_list) if keep]

    if output_txt:
        output_txt = Path(output_txt)
        output_txt.write_text("\n".join([str(file) for file in trimmed_to_keep]) + "\n")

    return trimmed_to_keep


if "snakemake" in locals():
    with open(snakemake.log[0], "w") as f:
        sys.stderr = sys.stdout = f

        filter_alignments(
            trimmed_alignment_paths=snakemake.input['trimmed'], 
            untrimmed_alignment_paths=snakemake.input['untrimmed'], 
            output_txt=snakemake.output[0],
            min_length=snakemake.params['min_length'],
            max_trimmed_proportion=snakemake.params['max_trimmed_proportion'],
            n_jobs=snakemake.threads, 
        )
elif __name__ == "__main__":
    app()



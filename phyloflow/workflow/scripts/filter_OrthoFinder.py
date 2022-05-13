#!/usr/bin/env python3
import re
import shutil
import subprocess
from pathlib import Path

import typer
from rich.progress import BarColumn, Progress, TextColumn


def main(
    indir: Path = typer.Argument(..., exists=True, file_okay=False, dir_okay=True),
    outdir: Path = typer.Argument(..., exists=False, file_okay=False, dir_okay=True),
    minseq: int = typer.Argument(...),
):

    # prepare output directory
    outdir.mkdir()

    # filter OGs that have >= minseq sequences
    og_dir = indir / "Orthogroup_Sequences"
    gt_dir = indir / "Gene_Trees"
    fastaInputFiles = list(og_dir.glob('*.fa'))
    pattern = re.compile(r"(OG\d+)\.fa")

    with Progress(*Progress.get_default_columns(), TextColumn("({task.completed})")) as progress:
        task_files = progress.add_task("Processing...", total=len(fastaInputFiles))
        task_kept = progress.add_task("[green]Kept...", total=None)
        task_skipped = progress.add_task("[red]Skipped...", total=None)

        for fasta_file in fastaInputFiles:
            progress.update(task_files, advance=1)
            grepout = subprocess.check_output(f"grep -c '>' {fasta_file}", shell=True)
            nseq = int(str(grepout, 'UTF-8'))
            if nseq >= minseq:
                shutil.copyfile(fasta_file, outdir / fasta_file.name)
                og = pattern.search(str(fasta_file)).group(1)
                shutil.copyfile(gt_dir / (og + "_tree.txt"), outdir / (og + ".nwk"))
                progress.update(task_kept, advance=1)
            else:
                progress.update(task_skipped, advance=1)


if __name__ == "__main__":
    typer.run(main)

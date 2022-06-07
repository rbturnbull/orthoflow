#!/usr/bin/env python3
import re
import shutil
from pathlib import Path

import typer
from rich.progress import Progress, TextColumn


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
            fasta = fasta_file.read_text()
            fasta = fasta.replace(';', '_')
            nseq = fasta.count('>')
            if nseq >= minseq:
                (outdir / fasta_file.name).write_text(fasta)
                og = pattern.search(str(fasta_file)).group(1)
                shutil.copyfile(gt_dir / (og + "_tree.txt"), outdir / (og + ".nwk"))
                progress.update(task_kept, advance=1)
            else:
                progress.update(task_skipped, advance=1)


if __name__ == "__main__":
    typer.run(main)

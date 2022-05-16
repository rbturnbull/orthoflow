import sys
from pathlib import Path
from typing import Optional

import snakemake
import typer

app = typer.Typer()


def _print_snakemake_help(value: bool):
    if value:
        snakemake.main("-h")


@app.command(
    context_settings={"allow_extra_args": True, "ignore_unknown_options": True, "help_option_names": ["-h", "--help"]},
)
def run(
    ctx: typer.Context,
    directory: Path = typer.Argument(..., file_okay=False, exists=True, dir_okay=True),
    cores: Optional[int] = typer.Option(1, "--cores", "-c", help="Number of cores to request for the workflow"),
    help_snakemake: Optional[bool] = typer.Option(
        False,
        "--help-snakemake",
        help="Print the snakemake help",
        is_eager=True,
        callback=_print_snakemake_help,
    ),
):
    snakefile = Path(__file__).parent / "workflow/Snakefile"
    args = [
        f"--snakefile={snakefile}",
        "--use-conda",
        f"--cores={cores}",
        f"--directory={directory}",
        *ctx.args,
    ]

    typer.secho("Running phyloflow...", fg=typer.colors.GREEN)
    typer.secho(f"snakemake {' '.join(args)}", fg=typer.colors.BLACK)
    status = snakemake.main(args)

    sys.exit(0 if status else 1)

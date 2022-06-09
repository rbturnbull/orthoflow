import subprocess
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
    directory: Optional[Path] = typer.Option(Path("."), file_okay=False, exists=True, dir_okay=True),
    cores: Optional[int] = typer.Option(1, "--cores", "-c", help="Number of cores to request for the workflow"),
    help_snakemake: Optional[bool] = typer.Option(
        False,
        "--help-snakemake",
        help="Print the snakemake help",
        is_eager=True,
        callback=_print_snakemake_help,
    ),
):
    """
    \b
     ____  _           _        __ _
    |  _ \| |__  _   _| | ___  / _| | _____      __
    | |_) | '_ \| | | | |/ _ \| |_| |/ _ \ \ /\ / /
    |  __/| | | | |_| | | (_) |  _| | (_) \ V  V /
    |_|   |_| |_|\__, |_|\___/|_| |_|\___/ \_/\_/
                 |___/

    All unrecognised arguments will be passed directly to Snakemake. Use `phyloflow --help-snakemake` to list all
    arguments accepted by Snakemake.
    """  # noqa: W605

    snakefile = Path(__file__).parent / "workflow/Snakefile"

    mamba_found = True
    try:
        subprocess.run(["mamba", "--version"], capture_output=True, check=True)
    except (subprocess.CalledProcessError, FileNotFoundError):
        mamba_found = False

    args = [
        f"--snakefile={snakefile}",
        "--use-conda",
        f"--cores={cores}",
        f"--directory={directory}",
    ]
    if not mamba_found:
        args.append("--conda-frontend=conda")
    if ctx.args:
        args.extend(ctx.args)

    typer.secho("Running phyloflow...", fg=typer.colors.GREEN)
    typer.secho(f"snakemake {' '.join(args)}", fg=typer.colors.BLACK)
    status = snakemake.main(args)

    sys.exit(0 if status else 1)

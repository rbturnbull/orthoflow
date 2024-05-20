import re
import subprocess
import sys
from pathlib import Path
from typing import Optional, List

import snakemake
import typer
from appdirs import user_cache_dir

app = typer.Typer()


def _print_snakemake_help(value: bool):
    if value:
        snakemake.main("-h")


def get_default_conda_prefix() -> Path:
    return Path(user_cache_dir("orthoflow"))/"conda"


@app.command(
    context_settings={"allow_extra_args": True, "ignore_unknown_options": True, "help_option_names": ["-h", "--help"]},
)
def run(
    ctx: typer.Context,
    files: List[Path] = typer.Option(None, help="The input source files"),
    target: Optional[Path] = typer.Option(None, help="The target file to create"),
    directory: Optional[Path] = typer.Option(Path("."), file_okay=False, exists=True, dir_okay=True),
    cores: Optional[int] = typer.Option(None, "--cores", "-c", help="Number of cores to request for the workflow. If not given then it will use all available available CPU cores."),
    conda_prefix:Path = typer.Option(
        None, 
        envvar="ORTHOFLOW_CONDA_PREFIX", 
        help="A directory to use for created conda environments. If none given then it will use the user cache directory.",
    ),
    hpc: bool = typer.Option(False, help="Run on an HPC cluster (with the SLURM scheduler)?"),
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
      ___      _   _         __ _            
     / _ \ _ _| |_| |_  ___ / _| |_____ __ __
    | (_) | '_|  _| ' \/ _ \  _| / _ \ V  V /
     \___/|_|  \__|_||_\___/_| |_\___/\_/\_/ 
                                                                                                                                                                                                                     
    All unrecognized arguments will be passed directly to Snakemake. Use `orthoflow --help-snakemake` to list all
    arguments accepted by Snakemake.
    """  # noqa: W605

    snakefile = Path(__file__).parent / "workflow/Snakefile"

    conda_prefix = conda_prefix or get_default_conda_prefix()

    args = [
        f"--snakefile={snakefile}",
        "--use-conda",
        f"--cores={cores}" if cores else "--cores",
        f"--directory={directory}",
        f"--conda-prefix={conda_prefix}",
        # f"--rerun-triggers=mtime", # hack for issue #69
    ]

    # Check if mamba is available, otherwise use conda
    mamba_found = True
    try:
        subprocess.run(["mamba", "--version"], capture_output=True, check=True)
    except (subprocess.CalledProcessError, FileNotFoundError):
        mamba_found = False
    if not mamba_found:
        args.append("--conda-frontend=conda")
        
    if target:
        args.append(str(target))

    if all(('profile' not in re.split(r' |=', arg)[0] for arg in ctx.args)):
        if hpc:
            args.append(f"--profile={Path(__file__).parent.resolve()/'profiles/slurm'}")
        else:
            args.append(f"--profile={Path(__file__).parent.resolve()/'profiles/local'}")

    if ctx.args:
        args.extend(ctx.args)

    if files:
        files = ",".join([str(x) for x in files])
        files_arg = f"input_sources={files}"
        if "--config" in args:
            config_index = args.index("--config")
            args.insert(config_index+1, files_arg)
        else:
            args.extend(["--config", files_arg])

    typer.secho("Running orthoflow...", fg=typer.colors.GREEN)
    typer.secho(f"snakemake {' '.join(args)}", fg=typer.colors.BLACK)
    status = snakemake.main(args)

    sys.exit(0 if status else 1)

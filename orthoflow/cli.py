from pathlib import Path
import typer
from snk_cli import CLI

orthoflow = CLI(Path(__file__).parent)


@orthoflow.app.command()
def bibtex():
    """ Print the BibTeX file for Orthoflow. """
    bibfile = Path(__file__).parent / "workflow" / "bibs" / "orthoflow.bib"
    print(bibfile.read_text().strip())


@orthoflow.app.command()
def github():
    """ Launch the Orthoflow GitHub page. """
    typer.launch("https://github.com/rbturnbull/orthoflow")


@orthoflow.app.command()
def docs():
    """ Launch the Orthoflow documentation. """
    typer.launch("https://rbturnbull.github.io/orthoflow/")

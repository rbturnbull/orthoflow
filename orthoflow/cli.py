from pathlib import Path

from snk_cli import CLI

orthoflow = CLI(Path(__file__).parent)


@orthoflow.app.command()
def bibtex():
    """ Print the BibTeX file for Orthoflow. """
    bibfile = Path(__file__).parent / "workflow" / "bibs" / "orthoflow.bib"
    print(bibfile.read_text())

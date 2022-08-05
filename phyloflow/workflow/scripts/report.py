from pathlib import Path
import jinja2
from jinja2 import select_autoescape

import typer


def report(
    output: Path = typer.Option(..., help="The path to output the report."),
    supermatrix_render_svg: Path = None,
    supermatrix_alignment_summary: Path = None,
):
    report_dir = Path(__file__).parent.parent/"report"
    loader = jinja2.FileSystemLoader(report_dir)
    env = jinja2.Environment(
        loader=loader,
        autoescape=jinja2.select_autoescape()
    )
    def include_file(name:Path):
        if name:
            return name.read_text()
        return ""

    env.globals['include_file'] = include_file

    template = env.get_template("report-template.html")
    result = template.render(
        supermatrix_render_svg=supermatrix_render_svg.resolve(),
        supermatrix_alignment_summary=supermatrix_alignment_summary,
    )
    with open(output, 'w') as f:
        print(f"Writing result to {output}")
        f.write(result)


if __name__ == "__main__":
    typer.run(report)

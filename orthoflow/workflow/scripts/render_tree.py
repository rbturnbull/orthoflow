#!/usr/bin/env python3
from pathlib import Path
import toytree
import toyplot.svg
import toyplot.html
import toyplot.png
import typer

def render_tree(
    tree_file: Path = typer.Argument(..., help="The path to the tree file in newick format."),
    svg: Path = typer.Option(None, file_okay=False, help="A path to output an SVG."),
    png: Path = typer.Option(None, file_okay=False, help="A path to output a PNG."),
    html: Path = typer.Option(None, file_okay=False, help="A path to output an HTML file."),
    width: int = typer.Option(1000, help="The width of the rendered image."),
    height: int = typer.Option(None, help="The height of the rendered image."),
    tip_labels_align: bool = typer.Option(True, help="Whether or not to align the tip labels."),
):
    tree = toytree.tree(str(tree_file))
    canvas, axes, mark = tree.draw(
        width=width, 
        height=height, 
        node_hover=True, 
        node_sizes=20, 
        node_labels='support',
        tip_labels_align=tip_labels_align
    )
    if png:
        toyplot.png.render(canvas, str(png))
    if svg:
        toyplot.svg.render(canvas, str(svg))
    if html:
        toyplot.html.render(canvas, str(html))



if __name__ == "__main__":
    typer.run(render_tree)


def format_fig(fig):
    """Formats a plotly figure in a nicer way."""
    fig.update_layout(
        width=1000,
        height=600,
        plot_bgcolor="white",
        title_font_color="black",
        font=dict(
            family="Linus Libertinus",        
            size=18,
            color="black",
        ),
    )
    gridcolor = "#dddddd"
    fig.update_xaxes(gridcolor=gridcolor)
    fig.update_yaxes(gridcolor=gridcolor)

    fig.update_xaxes(showline=True, linewidth=1, linecolor='black', mirror=True, ticks='outside', zeroline=True, zerolinewidth=1, zerolinecolor='black')
    fig.update_yaxes(showline=True, linewidth=1, linecolor='black', mirror=True, ticks='outside', zeroline=True, zerolinewidth=1, zerolinecolor='black')

    return fig

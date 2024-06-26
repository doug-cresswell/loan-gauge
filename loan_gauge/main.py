"""
This module sets up and runs a Dash web app for visualizing mortgage payment schedules.

Utilizing data generated by the mortgage module, this app presents a stacked area chart
showing the breakdown of principal and interest payments over time, along with a detailed
table view of the payment schedule.

The app provides an interactive interface for users to explore how payments contribute
towards reducing the principal over the term of the mortgage.
"""

import dash
import plotly.express as px
import plotly.graph_objs as go
from dash import Input, Output, callback, dash_table, dcc, html
from mortgage import generate_mortgage_schedule

# Create dataset of mortgage monthly payments
df = generate_mortgage_schedule(
    principal=300000, annual_interest_rate=4.5 / 100, years=25
)

# Initialize the app
app = dash.Dash(__name__)


# App layout
app.layout = html.Div(
    children=[
        html.H1(children="Mortgage Payments Interest vs Principal"),
        dcc.RadioItems(
            options=[25],
            value=25,
            id="years",
        ),
        dcc.Graph(id="interest-vs-principal-graph"),
        html.H1(children="Mortgage Payments Overview"),
        dcc.RadioItems(
            options=df.columns,
            value="Remaining Balance",
            id="controls-and-radio-item",
        ),
        dcc.Graph(figure={}, id="controls-and-graph"),
        html.Hr(),
        html.H2(children="Payment Details"),
        dash_table.DataTable(
            id="table",
            columns=[{"name": i, "id": i} for i in df.columns],
            data=df.to_dict("records"),
        ),
    ]
)


# Add controls to build the interaction
@callback(
    Output(component_id="controls-and-graph", component_property="figure"),
    Input(component_id="controls-and-radio-item", component_property="value"),
)
def update_graph(col_chosen):
    """Interactive area chart where you can choose the Dataframe column displayed."""
    fig = px.area(df, x="Month", y=col_chosen)
    return fig


@app.callback(Output("interest-vs-principal-graph", "figure"), Input("years", "value"))
def display_area(years):
    """Display stacked area chart of cumulative interest and principal payments."""
    figure = {
        "data": [
            go.Scatter(
                x=df["Month"],
                y=df["Principal Paid"],
                stackgroup="one",
                name="Principal Paid",
            ),
            go.Scatter(
                x=df["Month"],
                y=df["Interest Paid"],
                stackgroup="one",
                name="Interest Paid",
            ),
        ],
        "layout": go.Layout(
            title="Mortgage Payments (Principal vs Interest)",
            xaxis={"title": "Month"},
            yaxis={"title": "Amount Paid"},
        ),
    }
    return figure


if __name__ == "__main__":
    app.run_server(debug=True)

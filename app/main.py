import dash
import dash_table
import dash_core_components as dcc
import dash_html_components as html
from dash.dependencies import Input, Output
import plotly.graph_objs as go
import pandas as pd
from mortgage import monthly_payments

# Create dataset of mortgage monthly payments
df_payments = monthly_payments()

app = dash.Dash(__name__)

app.layout = html.Div(
    children=[
        html.H1(children="Mortgage Payments Overview"),
        dcc.Graph(
            id="mortgage-stacked-area",
            figure={
                "data": [
                    go.Scatter(
                        x=df_payments["Month"],
                        y=df_payments["Principal Paid"],
                        stackgroup="one",
                        name="Principal Paid",
                    ),
                    go.Scatter(
                        x=df_payments["Month"],
                        y=df_payments["Interest Paid"],
                        stackgroup="one",
                        name="Interest Paid",
                    ),
                ],
                "layout": go.Layout(
                    title="Mortgage Payments (Principal vs Interest)",
                    xaxis={"title": "Month"},
                    yaxis={"title": "Amount Paid"},
                ),
            },
        ),
        html.H2(children="Payment Details"),
        dash_table.DataTable(
            id="table",
            columns=[{"name": i, "id": i} for i in df_payments.columns],
            data=df_payments.to_dict("records"),
        ),
    ]
)

if __name__ == "__main__":
    app.run_server(debug=True)

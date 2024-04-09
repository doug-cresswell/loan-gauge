"""Mortgage data calculations."""

import pandas as pd
import numpy as np


def monthly_payments(
    principal=300000,  # Principal loan amount
    annual_interest_rate=0.04,  # Annual interest rate
    years=25,  # Mortgage term in years
):

    monthly_interest_rate = annual_interest_rate / 12
    n_payments = years * 12

    # Monthly mortgage payment (fixed-rate)
    monthly_payment = np.pmt(monthly_interest_rate, n_payments, -principal)

    # Months
    months = np.arange(1, n_payments + 1)

    # Interest Paid Each Month
    interest_paid = np.ipmt(monthly_interest_rate, months, n_payments, -principal)

    # Principal Paid Each Month
    principal_paid = np.ppmt(monthly_interest_rate, months, n_payments, -principal)

    # Cumulative Principal Paid
    cumulative_principal_paid = np.cumsum(principal_paid)

    # Remaining Balance Each Month
    remaining_balance = principal + cumulative_principal_paid

    # Creating DataFrame
    df = pd.DataFrame(
        {
            "Month": months,
            "Principal Paid": -principal_paid,  # Negate to make positive
            "Interest Paid": -interest_paid,  # Negate to make positive
            "Remaining Balance": remaining_balance,
            "Total Paid": -(
                principal_paid + interest_paid
            ),  # Sum and negate to make positive
        }
    )

    return df

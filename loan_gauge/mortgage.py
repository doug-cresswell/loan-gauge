"""
This module contains utilities for calculating and generating mortgage payment schedules.

The primary functionality includes generating a DataFrame that details each payment
throughout the life of a mortgage, breaking down the amount that goes towards the
principal versus interest, along with the remaining balance over time.

Functions:
    generate_mortgage_schedule(principal, annual_interest_rate, years): Generates a
        DataFrame containing the mortgage schedule.
"""

import pandas as pd
import numpy as np


def generate_mortgage_schedule(
    principal: float, annual_interest_rate: float, years: int
) -> pd.DataFrame:
    """
    Generates a DataFrame representing the mortgage payment schedule over time.

    Given a principal loan amount, an annual interest rate, and the loan term in years,
    this function calculates the monthly payment, interest paid, principal paid, and
    remaining balance for each month until the loan is paid off.

    Args:
        principal (float): The total amount of the loan.
        annual_interest_rate (float): The annual interest rate as a decimal (e.g., 0.04 for 4%).
        years (int): The term of the loan in years.

    Returns:
        pd.DataFrame: A DataFrame with columns for each month's payment amount towards
            principal, interest, the remaining balance, and the cumulative amount paid.
    """

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
            "Monthly Payment": monthly_payment,
            "Principal Paid": -principal_paid,  # Negate to make positive
            "Interest Paid": -interest_paid,  # Negate to make positive
            "Remaining Balance": remaining_balance,
            "Total Paid": -(
                principal_paid + interest_paid
            ),  # Sum and negate to make positive
        }
    )

    return df

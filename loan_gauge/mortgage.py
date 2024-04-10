"""
This module contains utilities for calculating and generating mortgage payment schedules.

The primary functionality includes generating a DataFrame that details each payment
throughout the life of a mortgage, breaking down the amount that goes towards the
principal versus interest, along with the remaining balance over time.

Functions:
    generate_mortgage_schedule(principal, annual_interest_rate, years): Generates a
        DataFrame containing the mortgage schedule.
"""

import numpy as np
import numpy_financial as npf
import pandas as pd


def generate_mortgage_schedule(
    principal: float, annual_interest_rate: float, years: int
) -> pd.DataFrame:
    """
    Generate a DataFrame representing the mortgage payment schedule over time.

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
    monthly_payment = npf.pmt(monthly_interest_rate, n_payments, -principal)

    months = np.arange(1, n_payments + 1)

    # Paid Each Month
    monthly_interest = npf.ipmt(monthly_interest_rate, months, n_payments, -principal)
    monthly_principle = npf.ppmt(monthly_interest_rate, months, n_payments, -principal)

    # Cumulative Totals Each Month
    cumulative_interest = np.cumsum(monthly_interest)
    cumulative_principal = np.cumsum(monthly_principle)
    cumulative_payment = cumulative_interest + cumulative_principal

    # Remaining Balance Each Month
    remaining_balance = principal - cumulative_principal

    # Creating DataFrame
    df = pd.DataFrame(
        {
            # TODO: apply np.round to monetary cols
            "Month": months,
            "Monthly Payment": np.round(monthly_payment, 2),
            "Monthly Principal": np.round(monthly_principle, 2),
            "Monthly Interest": np.round(monthly_interest, 2),
            "Interest Paid": np.round(cumulative_interest),
            "Principal Paid": np.round(cumulative_principal),
            "Total Paid": np.round(cumulative_payment, 2),
            "Remaining Balance": np.round(remaining_balance, 2),
        }
    )

    return df

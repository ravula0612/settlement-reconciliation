# Transaction settlement reconciliation

A SQL portfolio project inspired by an [Upwork fintech reconciliation brief](https://www.upwork.com/freelance-jobs/apply/Senior-Data-Engineer-Needed-for-Hour-SQL-Data-Reconciliation-Task-FinTech_~022118489865530611130/). All examples are synthetic.

Run from this directory with Python 3 and SQLite 3.25 or newer. No Python packages are required.

    python run.py
    python run.py --database my_inputs.sqlite > report.csv

The default demo prints one CSV row per transaction identifier observed on either side. To bring your own data, populate the events and settlements tables defined in run.py. The runner opens your database read-only.

## Reconciliation rules

Use a complete snapshot for a single currency and reporting cutoff. Amounts are integer minor units. Only the latest captured status creates an obligation. Use fixed-width UTC timestamps and an increasing event ID to break ties. Settlement IDs must uniquely identify actual postings. Multiple postings against one transaction are added before comparison. The demo assumes settlements are due by the cutoff and excludes refunds, fees and FX.

A positive variance means more settled than expected. A missing settlement is detected from posting count, so even a zero-value captured transaction with no posting can be reviewed.

## Sample findings

The six identifiers in expected.csv include a matched split settlement, a missing settlement of 500 minor units, a short settlement of 50, a posting against a failed transaction, a failed transaction with no posting, and a posting with no transaction history.

To check the demo output on Linux or macOS:

    python run.py | diff - expected.csv

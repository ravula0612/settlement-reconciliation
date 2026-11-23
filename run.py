"""Run the SQL reconciliation against a local SQLite database or the demo."""
import argparse
import csv
import sqlite3
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SCHEMA = """
CREATE TABLE events (
    event_id INTEGER PRIMARY KEY, txn_id TEXT NOT NULL, occurred_at TEXT NOT NULL,
    status TEXT NOT NULL CHECK(status IN ('pending','captured','failed')),
    amount_minor INTEGER NOT NULL CHECK(amount_minor >= 0)
);
CREATE TABLE settlements (
    settlement_id TEXT PRIMARY KEY NOT NULL, txn_id TEXT NOT NULL,
    amount_minor INTEGER NOT NULL CHECK(amount_minor >= 0)
);
"""


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--database", type=Path, help="Existing SQLite input database")
    args = parser.parse_args()
    if args.database:
        db = sqlite3.connect(args.database.resolve().as_uri() + "?mode=ro", uri=True)
    else:
        db = sqlite3.connect(":memory:")
    try:
        if args.database is None:
            db.executescript(SCHEMA)
            db.executescript((ROOT / "sample.sql").read_text())
        rows = db.execute((ROOT / "reconcile.sql").read_text())
        writer = csv.writer(sys.stdout, lineterminator="\n")
        writer.writerow(column[0] for column in rows.description)
        writer.writerows(rows)
    finally:
        db.close()


if __name__ == "__main__":
    main()

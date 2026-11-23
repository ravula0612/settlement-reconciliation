-- Input timestamps are normalized UTC strings. event_id orders simultaneous updates.
WITH ranked AS (
    SELECT e.*, ROW_NUMBER() OVER (
        PARTITION BY txn_id ORDER BY occurred_at DESC, event_id DESC
    ) AS recency
    FROM events AS e
),
received AS (
    SELECT txn_id, SUM(amount_minor) AS settled_minor, COUNT(*) AS settlement_count
    FROM settlements GROUP BY txn_id
),
ids AS (
    SELECT txn_id FROM events UNION SELECT txn_id FROM settlements
),
balances AS (
    SELECT ids.txn_id, e.status,
           CASE WHEN e.status = 'captured' THEN e.amount_minor ELSE 0 END AS expected_minor,
           COALESCE(r.settled_minor, 0) AS settled_minor,
           COALESCE(r.settlement_count, 0) AS settlement_count
    FROM ids
    LEFT JOIN ranked AS e ON e.txn_id = ids.txn_id AND e.recency = 1
    LEFT JOIN received AS r ON r.txn_id = ids.txn_id
)
SELECT *, settled_minor - expected_minor AS variance_minor,
       CASE WHEN settlement_count > 0 AND COALESCE(status, '') <> 'captured' THEN 'unexpected_settlement'
            WHEN status = 'captured' AND settlement_count = 0 THEN 'missing_settlement'
            WHEN settled_minor <> expected_minor THEN 'amount_mismatch'
            WHEN status = 'captured' THEN 'matched'
            ELSE 'no_settlement_due' END AS outcome
FROM balances ORDER BY txn_id;

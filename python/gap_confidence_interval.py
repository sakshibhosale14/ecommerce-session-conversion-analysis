"""Bootstrap 95% confidence interval for the morning-vs-afternoon conversion gap.

Run from the repo root (after sql/05 has built the session tables):
    python python/gap_confidence_interval.py

Method: resample whole DAYS with replacement (10,000 times) and recompute the gap each
time. Days are resampled instead of sessions because sessions from the same day and the
same users are not independent, so resampling sessions would give a falsely tight interval.
Morning = hours 5-9 UTC, afternoon = hours 14-16 UTC. Nov 15-17 are excluded.
Only 27-31 days per month are available, so the intervals are rough estimates.
"""
import random
import duckdb

rows = duckdb.sql("""
    WITH s AS (
        SELECT 'Oct' AS month, session_start, had_purchase
        FROM 'data/parquet/oct_session_table.parquet'
        UNION ALL
        SELECT 'Nov (excl. 15-17)', session_start, had_purchase
        FROM 'data/parquet/nov_session_table.parquet'
        WHERE day(session_start) NOT BETWEEN 15 AND 17
    )
    SELECT month, CAST(session_start AS DATE) AS dt,
           COUNT(CASE WHEN hour(session_start) BETWEEN 5 AND 9 THEN 1 END) AS m_sessions,
           SUM(CASE WHEN hour(session_start) BETWEEN 5 AND 9 THEN had_purchase ELSE 0 END) AS m_purchases,
           COUNT(CASE WHEN hour(session_start) BETWEEN 14 AND 16 THEN 1 END) AS a_sessions,
           SUM(CASE WHEN hour(session_start) BETWEEN 14 AND 16 THEN had_purchase ELSE 0 END) AS a_purchases
    FROM s
    GROUP BY month, dt
    ORDER BY month, dt
""").fetchall()


def gap(days):
    m_s = sum(d[2] for d in days)
    m_p = sum(d[3] for d in days)
    a_s = sum(d[4] for d in days)
    a_p = sum(d[5] for d in days)
    return 100 * (1 - (a_p / a_s) / (m_p / m_s))


random.seed(42)
for month in ["Oct", "Nov (excl. 15-17)"]:
    days = [r for r in rows if r[0] == month]
    point = gap(days)
    boots = sorted(gap(random.choices(days, k=len(days))) for _ in range(10000))
    lo, hi = boots[250], boots[9749]
    days_lower = sum(1 for d in days if d[5] / d[4] < d[3] / d[2])
    print(f"{month}: gap {point:.1f}%, 95% CI [{lo:.1f}%, {hi:.1f}%], "
          f"afternoon lower on {days_lower} of {len(days)} days")

# Result: Oct gap 35.4%, 95% CI [34.0%, 36.7%], afternoon lower on 31 of 31 days
#         Nov (excl. 15-17) gap 33.8%, 95% CI [32.2%, 35.2%], afternoon lower on 27 of 27 days

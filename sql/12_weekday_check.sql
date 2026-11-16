-- 12: Is the morning-vs-afternoon gap just a weekday/weekend effect?
-- Result: no. The weekend share is similar in both windows, and the gap holds
-- within weekdays and within weekends, in both months.
-- isodow: Monday = 1 ... Sunday = 7.
WITH s AS (
    SELECT 'Oct' AS month, session_start, had_purchase
    FROM 'data/parquet/oct_session_table.parquet'
    UNION ALL
    SELECT 'Nov (excl. 15-17)', session_start, had_purchase
    FROM 'data/parquet/nov_session_table.parquet'
    WHERE day(session_start) NOT BETWEEN 15 AND 17
),
labeled AS (
    SELECT month,
           CASE WHEN isodow(session_start) >= 6 THEN 'weekend' ELSE 'weekday' END AS day_type,
           CASE WHEN hour(session_start) BETWEEN 5 AND 9   THEN 'morning (5-9)'
                WHEN hour(session_start) BETWEEN 14 AND 16 THEN 'afternoon (14-16)' END AS period,
           had_purchase
    FROM s
)
SELECT month, day_type, period,
       COUNT(*) AS sessions,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY month, period), 1) AS share_in_period_pct,
       ROUND(100.0 * AVG(had_purchase), 2) AS conversion_pct
FROM labeled
WHERE period IS NOT NULL
GROUP BY month, day_type, period
ORDER BY month, day_type, period;

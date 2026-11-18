-- 08: Is the morning-vs-afternoon gap explained by category or visitor type?

-- Conversion by main category (October). Main category = the most common
-- first-level category in the session; 'unknown' if none.
WITH sess AS (
    SELECT user_id, session_num,
           COALESCE(mode(split_part(category_code, '.', 1)), 'unknown') AS main_category,
           MAX(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) AS had_purchase
    FROM 'data/parquet/oct_sessions.parquet'
    GROUP BY user_id, session_num
)
SELECT main_category,
       COUNT(*) AS sessions,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS share_of_sessions_pct,
       ROUND(100.0 * AVG(had_purchase), 2) AS conversion_pct
FROM sess
GROUP BY main_category
ORDER BY sessions DESC;

-- Category mix and conversion within morning vs afternoon
WITH sess AS (
    SELECT user_id, session_num,
           MIN(event_time) AS session_start,
           COALESCE(mode(split_part(category_code, '.', 1)), 'unknown') AS main_category,
           MAX(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) AS had_purchase
    FROM 'data/parquet/oct_sessions.parquet'
    GROUP BY user_id, session_num
),
labeled AS (
    SELECT *,
           CASE WHEN hour(session_start) BETWEEN 5 AND 9   THEN 'morning (5-9)'
                WHEN hour(session_start) BETWEEN 14 AND 16 THEN 'afternoon (14-16)'
           END AS period
    FROM sess
),
agg AS (
    SELECT period, main_category,
           COUNT(*) AS sessions,
           ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY period), 1) AS share_in_period_pct,
           ROUND(100.0 * AVG(had_purchase), 2) AS conversion_pct
    FROM labeled
    WHERE period IS NOT NULL
    GROUP BY period, main_category
)
SELECT * FROM agg
WHERE main_category IN ('electronics', 'unknown', 'appliances', 'computers', 'apparel')
ORDER BY main_category, period;

-- First session seen in October vs later sessions

WITH labeled AS (
    SELECT CASE WHEN hour(session_start) BETWEEN 5 AND 9   THEN 'morning (5-9)'
                WHEN hour(session_start) BETWEEN 14 AND 16 THEN 'afternoon (14-16)' END AS period,
           CASE WHEN session_num = 1 THEN 'first in Oct' ELSE 'later' END AS visit_type,
           had_purchase
    FROM 'data/parquet/oct_session_table.parquet'
)
SELECT period, visit_type,
       COUNT(*) AS sessions,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY period), 1) AS share_in_period_pct,
       ROUND(100.0 * AVG(had_purchase), 2) AS conversion_pct
FROM labeled
WHERE period IS NOT NULL
GROUP BY period, visit_type
ORDER BY visit_type, period;

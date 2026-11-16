-- 09: Does the October finding hold in November? (Holdout month.)
-- Also: how three abnormal days (Nov 15-17) were found and handled.
-- See docs/definitions.md, section 7.

-- November headline numbers
SELECT COUNT(*) AS sessions,
       COUNT(DISTINCT user_id) AS users,
       SUM(had_purchase) AS purchase_sessions,
       ROUND(100.0 * SUM(had_purchase) / COUNT(*), 2) AS conversion_pct,
       ROUND(SUM(revenue) / SUM(had_purchase), 2) AS rev_per_purchase_session
FROM 'data/parquet/nov_session_table.parquet';

-- Hourly conversion, October next to November
WITH o AS (
    SELECT hour(session_start) AS hr, COUNT(*) AS s, AVG(had_purchase) AS c
    FROM 'data/parquet/oct_session_table.parquet'
    GROUP BY hr
),
n AS (
    SELECT hour(session_start) AS hr, COUNT(*) AS s, AVG(had_purchase) AS c
    FROM 'data/parquet/nov_session_table.parquet'
    GROUP BY hr
)
SELECT o.hr,
       o.s AS oct_sessions, ROUND(100 * o.c, 2) AS oct_conv_pct,
       n.s AS nov_sessions, ROUND(100 * n.c, 2) AS nov_conv_pct
FROM o JOIN n USING (hr)
ORDER BY hr;

-- Morning vs afternoon conversion by block of days: finds the odd week in November
WITH all_s AS (
    SELECT 'Oct' AS month, session_start, had_purchase
    FROM 'data/parquet/oct_session_table.parquet'
    UNION ALL
    SELECT 'Nov', session_start, had_purchase
    FROM 'data/parquet/nov_session_table.parquet'
)
SELECT month,
       CASE WHEN day(session_start) <= 7  THEN 'a) days 1-7'
            WHEN day(session_start) <= 14 THEN 'b) days 8-14'
            WHEN day(session_start) <= 21 THEN 'c) days 15-21'
            ELSE                               'd) days 22-31' END AS days,
       ROUND(100 * AVG(CASE WHEN hour(session_start) BETWEEN 5 AND 9
                            THEN had_purchase END), 2) AS morning_conv_pct,
       ROUND(100 * AVG(CASE WHEN hour(session_start) BETWEEN 14 AND 16
                            THEN had_purchase END), 2) AS afternoon_conv_pct
FROM all_s
GROUP BY month, days
ORDER BY month, days;

-- Zoom in on Nov 12-24 to find the exact abnormal days
SELECT CAST(session_start AS DATE) AS dt,
       COUNT(CASE WHEN hour(session_start) BETWEEN 14 AND 16 THEN 1 END) AS afternoon_sessions,
       ROUND(100 * AVG(CASE WHEN hour(session_start) BETWEEN 5 AND 9 THEN had_purchase END), 2) AS morning_conv_pct,
       ROUND(100 * AVG(CASE WHEN hour(session_start) BETWEEN 14 AND 16 THEN had_purchase END), 2) AS afternoon_conv_pct
FROM 'data/parquet/nov_session_table.parquet'
WHERE day(session_start) BETWEEN 12 AND 24
GROUP BY dt
ORDER BY dt;

-- Nov 15: carts recorded but zero purchases (looks like a purchase-logging gap)
SELECT CAST(session_start AS DATE) AS dt,
       COUNT(*) AS sessions,
       SUM(had_cart) AS cart_sessions,
       SUM(had_purchase) AS purchase_sessions,
       ROUND(100.0 * SUM(had_purchase) / COUNT(*), 2) AS conversion_pct
FROM 'data/parquet/nov_session_table.parquet'
WHERE day(session_start) BETWEEN 13 AND 18
GROUP BY dt
ORDER BY dt;

-- Final comparison: October, all of November, and November without Nov 15-17
WITH s AS (
    SELECT 'Oct' AS grp, session_start, had_purchase
    FROM 'data/parquet/oct_session_table.parquet'
    UNION ALL
    SELECT 'Nov (all days)', session_start, had_purchase
    FROM 'data/parquet/nov_session_table.parquet'
    UNION ALL
    SELECT 'Nov (excl. 15-17)', session_start, had_purchase
    FROM 'data/parquet/nov_session_table.parquet'
    WHERE day(session_start) NOT BETWEEN 15 AND 17
)
SELECT grp,
       ROUND(100 * AVG(CASE WHEN hour(session_start) BETWEEN 5 AND 9
                            THEN had_purchase END), 2) AS morning_conv_pct,
       ROUND(100 * AVG(CASE WHEN hour(session_start) BETWEEN 14 AND 16
                            THEN had_purchase END), 2) AS afternoon_conv_pct,
       ROUND(100 * (1 - AVG(CASE WHEN hour(session_start) BETWEEN 14 AND 16 THEN had_purchase END)
                      / AVG(CASE WHEN hour(session_start) BETWEEN 5 AND 9 THEN had_purchase END)), 1)
           AS afternoon_lower_by_pct
FROM s
GROUP BY grp
ORDER BY grp;

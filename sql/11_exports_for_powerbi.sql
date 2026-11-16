-- 11: Small summary tables for the Power BI dashboard (committed in exports/).
-- Power BI never touches the 100M-row files, only these CSVs.

-- Hourly conversion: October vs cleaned November (Nov 15-17 excluded)
COPY (
    SELECT 'Oct' AS month, hour(session_start) AS hr,
           COUNT(*) AS sessions, SUM(had_purchase) AS purchases,
           ROUND(100.0 * AVG(had_purchase), 2) AS conversion_pct
    FROM 'data/parquet/oct_session_table.parquet' GROUP BY 2
    UNION ALL
    SELECT 'Nov (excl. 15-17)', hour(session_start),
           COUNT(*), SUM(had_purchase),
           ROUND(100.0 * AVG(had_purchase), 2)
    FROM 'data/parquet/nov_session_table.parquet'
    WHERE day(session_start) NOT BETWEEN 15 AND 17
    GROUP BY 2
    ORDER BY 1, 2
) TO 'exports/hourly_conversion.csv' (HEADER, DELIMITER ',');

-- Daily conversion, all 61 days (Nov 15-17 deliberately left visible)
COPY (
    SELECT CAST(session_start AS DATE) AS dt,
           COUNT(*) AS sessions, SUM(had_cart) AS cart_sessions,
           SUM(had_purchase) AS purchase_sessions,
           ROUND(100.0 * AVG(had_purchase), 2) AS conversion_pct
    FROM (
        SELECT session_start, had_cart, had_purchase FROM 'data/parquet/oct_session_table.parquet'
        UNION ALL
        SELECT session_start, had_cart, had_purchase FROM 'data/parquet/nov_session_table.parquet'
    )
    GROUP BY dt ORDER BY dt
) TO 'exports/daily_conversion.csv' (HEADER, DELIMITER ',');

-- Key metrics: October vs cleaned November
COPY (
    SELECT 'Oct' AS period,
           COUNT(*) AS sessions,
           COUNT(DISTINCT user_id) AS users,
           SUM(had_purchase) AS purchase_sessions,
           ROUND(100.0 * AVG(had_purchase), 2) AS conversion_pct,
           ROUND(SUM(revenue)) AS revenue,
           ROUND(SUM(revenue) / SUM(had_purchase), 2) AS rev_per_purchase
    FROM 'data/parquet/oct_session_table.parquet'
    UNION ALL
    SELECT 'Nov (excl. 15-17)',
           COUNT(*),
           COUNT(DISTINCT user_id),
           SUM(had_purchase),
           ROUND(100.0 * AVG(had_purchase), 2),
           ROUND(SUM(revenue)),
           ROUND(SUM(revenue) / SUM(had_purchase), 2)
    FROM 'data/parquet/nov_session_table.parquet'
    WHERE day(session_start) NOT BETWEEN 15 AND 17
) TO 'exports/kpis.csv' (HEADER, DELIMITER ',');

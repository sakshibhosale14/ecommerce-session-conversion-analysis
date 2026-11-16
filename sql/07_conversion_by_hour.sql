-- 07: Headline KPIs and conversion by hour of day (October). Hours are UTC.

-- Headline numbers (conversion 7.47%)
SELECT COUNT(*) AS sessions,
       COUNT(DISTINCT user_id) AS users,
       SUM(had_purchase) AS purchase_sessions,
       ROUND(100.0 * SUM(had_purchase) / COUNT(*), 2) AS conversion_pct,
       ROUND(SUM(revenue), 0) AS total_revenue,
       ROUND(SUM(revenue) / SUM(had_purchase), 2) AS rev_per_purchase_session,
       ROUND(SUM(revenue) / COUNT(*), 3) AS rev_per_session
FROM 'data/parquet/oct_session_table.parquet';

-- Conversion by hour: volume and conversion peak at different times
SELECT hour(session_start) AS hr,
       COUNT(*) AS sessions,
       ROUND(100.0 * AVG(had_purchase), 2) AS conversion_pct,
       ROUND(SUM(revenue) / COUNT(*), 3) AS rev_per_session
FROM 'data/parquet/oct_session_table.parquet'
GROUP BY hr
ORDER BY hr;

-- Are afternoon sessions just bounces? (Result: no. Hour 15 has fewer one-click
-- sessions and more events per session than hour 8.)
SELECT hour(session_start) AS hr,
       COUNT(*) AS sessions,
       ROUND(100.0 * AVG(CASE WHEN n_events = 1 THEN 1 ELSE 0 END), 1) AS single_event_pct,
       ROUND(AVG(n_events), 1) AS avg_events,
       ROUND(100.0 * AVG(had_purchase), 2) AS conversion_pct
FROM 'data/parquet/oct_session_table.parquet'
GROUP BY hr
ORDER BY hr;

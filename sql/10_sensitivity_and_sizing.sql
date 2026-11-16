-- 10: Robustness check and opportunity sizing.

-- Sensitivity: does the gap depend on the 30-minute session rule? (October)
-- Result: gap is 35.5% / 35.4% / 35.7% for 15 / 30 / 60 minutes.
-- Heavy query: sorts three copies of the October events. Needs plenty of memory.
WITH base AS (
    SELECT user_id, event_time, event_type,
           LAG(event_time) OVER (PARTITION BY user_id ORDER BY event_time) AS prev_time
    FROM 'data/parquet/oct.parquet'
),
gaps AS (
    SELECT *, date_diff('second', prev_time, event_time) / 60.0 AS gap_min
    FROM base
),
by_rule AS (
    SELECT g.*, r.rule_min,
           SUM(CASE WHEN g.prev_time IS NULL OR g.gap_min > r.rule_min THEN 1 ELSE 0 END)
               OVER (PARTITION BY g.user_id, r.rule_min
                     ORDER BY g.event_time ROWS UNBOUNDED PRECEDING) AS sn
    FROM gaps g
    CROSS JOIN (SELECT UNNEST([15, 30, 60]) AS rule_min) r
),
sess AS (
    SELECT rule_min, user_id, sn,
           MIN(event_time) AS session_start,
           MAX(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) AS had_purchase
    FROM by_rule
    GROUP BY rule_min, user_id, sn
)
SELECT rule_min,
       COUNT(*) AS sessions,
       ROUND(100.0 * AVG(had_purchase), 2) AS overall_conv_pct,
       ROUND(100 * AVG(CASE WHEN hour(session_start) BETWEEN 5 AND 9 THEN had_purchase END), 2) AS morning_pct,
       ROUND(100 * AVG(CASE WHEN hour(session_start) BETWEEN 14 AND 16 THEN had_purchase END), 2) AS afternoon_pct,
       ROUND(100 * (1 - AVG(CASE WHEN hour(session_start) BETWEEN 14 AND 16 THEN had_purchase END)
                      / AVG(CASE WHEN hour(session_start) BETWEEN 5 AND 9 THEN had_purchase END)), 1) AS afternoon_lower_by_pct
FROM sess
GROUP BY rule_min
ORDER BY rule_min;

-- Opportunity sizing: SCENARIOS, not forecasts.
-- If the afternoon (14-16 UTC) closed 10% / 25% / 50% of its conversion gap to the morning,
-- how much extra revenue would that be? Assumes extra purchases are worth the
-- afternoon's average purchase.
WITH s AS (
    SELECT 'Oct' AS grp, session_start, had_purchase, revenue
    FROM 'data/parquet/oct_session_table.parquet'
    UNION ALL
    SELECT 'Nov (excl. 15-17)', session_start, had_purchase, revenue
    FROM 'data/parquet/nov_session_table.parquet'
    WHERE day(session_start) NOT BETWEEN 15 AND 17
),
agg AS (
    SELECT grp,
           COUNT(CASE WHEN hour(session_start) BETWEEN 14 AND 16 THEN 1 END) AS aft_sessions,
           AVG(CASE WHEN hour(session_start) BETWEEN 5 AND 9 THEN had_purchase END)   AS m_conv,
           AVG(CASE WHEN hour(session_start) BETWEEN 14 AND 16 THEN had_purchase END) AS a_conv,
           SUM(CASE WHEN hour(session_start) BETWEEN 14 AND 16 THEN revenue END)
             / NULLIF(SUM(CASE WHEN hour(session_start) BETWEEN 14 AND 16 THEN had_purchase END), 0)
             AS aft_rev_per_purchase,
           SUM(revenue) AS total_rev
    FROM s
    GROUP BY grp
),
scen AS (SELECT UNNEST([0.10, 0.25, 0.50]) AS closed_share),
calc AS (
    SELECT grp, closed_share,
           aft_sessions * (m_conv - a_conv) * closed_share AS extra_purchases,
           aft_rev_per_purchase, total_rev
    FROM agg CROSS JOIN scen
)
SELECT grp,
       closed_share AS share_of_gap_closed,
       ROUND(extra_purchases) AS extra_purchase_sessions,
       ROUND(extra_purchases * aft_rev_per_purchase) AS extra_revenue,
       ROUND(100 * extra_purchases * aft_rev_per_purchase / total_rev, 2) AS pct_of_month_revenue
FROM calc
ORDER BY grp, closed_share;

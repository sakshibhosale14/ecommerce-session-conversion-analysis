-- 05: One row per session, for October and November.
-- Every later analysis is a GROUP BY on these two tables.
-- Revenue = sum of price on purchase events with price > 0 (no quantity column).

-- October (from the sessionized events built in 03)
COPY (
    SELECT user_id, session_num,
           MIN(event_time) AS session_start,
           MAX(event_time) AS session_end,
           ROUND(date_diff('second', MIN(event_time), MAX(event_time)) / 60.0, 1) AS duration_min,
           COUNT(*) AS n_events,
           COUNT(DISTINCT product_id) AS n_products,
           MAX(CASE WHEN event_type = 'view'     THEN 1 ELSE 0 END) AS had_view,
           MAX(CASE WHEN event_type = 'cart'     THEN 1 ELSE 0 END) AS had_cart,
           MAX(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) AS had_purchase,
           SUM(CASE WHEN event_type = 'purchase' AND price > 0 THEN price ELSE 0 END) AS revenue
    FROM 'data/parquet/oct_sessions.parquet'
    GROUP BY user_id, session_num
) TO 'data/parquet/oct_session_table.parquet' (FORMAT PARQUET);

-- November (same rules, sessionized and aggregated in one step)
COPY (
    WITH ordered AS (
        SELECT user_id, event_time, event_type, product_id, price,
               LAG(event_time) OVER (PARTITION BY user_id ORDER BY event_time) AS prev_time
        FROM 'data/parquet/nov.parquet'
    ),
    flagged AS (
        SELECT *,
               CASE WHEN prev_time IS NULL
                      OR event_time - prev_time > INTERVAL 30 MINUTE
                    THEN 1 ELSE 0 END AS new_session
        FROM ordered
    ),
    numbered AS (
        SELECT *,
               SUM(new_session) OVER (
                   PARTITION BY user_id ORDER BY event_time
                   ROWS UNBOUNDED PRECEDING
               ) AS session_num
        FROM flagged
    )
    SELECT user_id, session_num,
           MIN(event_time) AS session_start,
           MAX(event_time) AS session_end,
           ROUND(date_diff('second', MIN(event_time), MAX(event_time)) / 60.0, 1) AS duration_min,
           COUNT(*) AS n_events,
           COUNT(DISTINCT product_id) AS n_products,
           MAX(CASE WHEN event_type = 'view'     THEN 1 ELSE 0 END) AS had_view,
           MAX(CASE WHEN event_type = 'cart'     THEN 1 ELSE 0 END) AS had_cart,
           MAX(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) AS had_purchase,
           SUM(CASE WHEN event_type = 'purchase' AND price > 0 THEN price ELSE 0 END) AS revenue
    FROM numbered
    GROUP BY user_id, session_num
) TO 'data/parquet/nov_session_table.parquet' (FORMAT PARQUET);

-- Checks (October should be 7,796,425 sessions; November 10,959,755)
SELECT COUNT(*) AS oct_sessions FROM 'data/parquet/oct_session_table.parquet';
SELECT COUNT(*) AS nov_sessions FROM 'data/parquet/nov_session_table.parquet';

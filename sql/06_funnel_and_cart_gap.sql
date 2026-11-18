-- 06: The funnel, and why session conversion (not cart steps) is the primary metric.
-- Funnel counts per session (October).

WITH session_flags AS (
    SELECT user_id, session_num,
           MAX(CASE WHEN event_type = 'view'     THEN 1 ELSE 0 END) AS had_view,
           MAX(CASE WHEN event_type = 'cart'     THEN 1 ELSE 0 END) AS had_cart,
           MAX(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) AS had_purchase
    FROM 'data/parquet/oct_sessions.parquet'
    GROUP BY user_id, session_num
)
SELECT COUNT(*) AS sessions,
       SUM(had_view)     AS view_sessions,
       SUM(had_cart)     AS cart_sessions,
       SUM(had_purchase) AS purchase_sessions,
       SUM(CASE WHEN had_purchase = 1 AND had_cart = 0 THEN 1 ELSE 0 END) AS purchase_without_cart,
       SUM(CASE WHEN had_view = 0 THEN 1 ELSE 0 END) AS sessions_without_view
FROM session_flags;

WITH flags AS (
    SELECT user_id, session_num,
           MAX(CASE WHEN event_type = 'cart' THEN 1 ELSE 0 END) AS had_cart
    FROM 'data/parquet/oct_sessions.parquet'
    GROUP BY user_id, session_num
),
np AS (
    SELECT s.user_id, s.session_num, s.product_id, s.event_time
    FROM 'data/parquet/oct_sessions.parquet' s
    JOIN flags f USING (user_id, session_num)
    WHERE s.event_type = 'purchase' AND f.had_cart = 0
),
carts AS (
    SELECT user_id, product_id, event_time
    FROM 'data/parquet/oct_sessions.parquet'
    WHERE event_type = 'cart'
)
SELECT
    COUNT(DISTINCT np.user_id || '-' || np.session_num) AS no_cart_purchase_sessions,
    COUNT(DISTINCT CASE WHEN c.event_time < np.event_time
                        THEN np.user_id || '-' || np.session_num END) AS had_earlier_cart_same_product
FROM np
LEFT JOIN carts c
  ON c.user_id = np.user_id AND c.product_id = np.product_id;

WITH flags AS (
    SELECT user_id, session_num,
           MAX(CASE WHEN event_type = 'cart' THEN 1 ELSE 0 END) AS had_cart
    FROM 'data/parquet/oct_sessions.parquet'
    GROUP BY user_id, session_num
),
np AS (
    SELECT s.user_id, s.session_num, s.product_id, s.event_time
    FROM 'data/parquet/oct_sessions.parquet' s
    JOIN flags f USING (user_id, session_num)
    WHERE s.event_type = 'purchase' AND f.had_cart = 0
),
carts AS (
    SELECT user_id, product_id, event_time
    FROM 'data/parquet/oct_sessions.parquet'
    WHERE event_type = 'cart'
),
res AS (
    SELECT CASE WHEN day(np.event_time) <= 7  THEN 'a) Oct 1-7'
                WHEN day(np.event_time) <= 14 THEN 'b) Oct 8-14'
                WHEN day(np.event_time) <= 21 THEN 'c) Oct 15-21'
                ELSE                               'd) Oct 22-31' END AS period,
           COUNT(DISTINCT np.user_id || '-' || np.session_num) AS no_cart_purchase_sessions,
           COUNT(DISTINCT CASE WHEN c.event_time < np.event_time
                               THEN np.user_id || '-' || np.session_num END) AS had_earlier_cart
    FROM np
    LEFT JOIN carts c
      ON c.user_id = np.user_id AND c.product_id = np.product_id
    GROUP BY period
)
SELECT *, ROUND(100.0 * had_earlier_cart / no_cart_purchase_sessions, 1) AS pct_explained
FROM res
ORDER BY period;

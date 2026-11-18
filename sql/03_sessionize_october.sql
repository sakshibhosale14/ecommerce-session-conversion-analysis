-- 03: Build sessions for October with a 30-minute inactivity rule.

COPY (
    WITH ordered AS (
        SELECT user_id, event_time, event_type, product_id,
               category_code, brand, price,
               LAG(event_time) OVER (PARTITION BY user_id ORDER BY event_time) AS prev_time
        FROM 'data/parquet/oct.parquet'
    ),
    flagged AS (
        SELECT *,
               CASE WHEN prev_time IS NULL
                      OR event_time - prev_time > INTERVAL 30 MINUTE
                    THEN 1 ELSE 0 END AS new_session
        FROM ordered
    )
    SELECT user_id, event_time, event_type, product_id,
           category_code, brand, price,
           SUM(new_session) OVER (
               PARTITION BY user_id ORDER BY event_time
               ROWS UNBOUNDED PRECEDING
           ) AS session_num
    FROM flagged
) TO 'data/parquet/oct_sessions.parquet' (FORMAT PARQUET);

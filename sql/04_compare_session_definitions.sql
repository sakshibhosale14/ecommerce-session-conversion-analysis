-- 04: Compare my 30-minute sessions with the dataset's own user_session column.
-- Session counts (mine: 7,796,425; dataset: 9,244,421)

SELECT COUNT(*) AS my_sessions FROM (
    SELECT DISTINCT user_id, session_num
    FROM 'data/parquet/oct_sessions.parquet'
);

SELECT COUNT(DISTINCT user_session) AS dataset_sessions
FROM 'data/parquet/oct.parquet';

WITH mine AS (
    SELECT user_id, COUNT(DISTINCT session_num) AS my_sessions
    FROM 'data/parquet/oct_sessions.parquet'
    GROUP BY user_id
),
theirs AS (
    SELECT user_id, COUNT(DISTINCT user_session) AS dataset_sessions
    FROM 'data/parquet/oct.parquet'
    GROUP BY user_id
)
SELECT CASE WHEN t.dataset_sessions > m.my_sessions THEN 'dataset has more'
            WHEN t.dataset_sessions < m.my_sessions THEN 'dataset has fewer'
            ELSE 'same' END AS comparison,
       COUNT(*) AS users
FROM mine m JOIN theirs t USING (user_id)
GROUP BY comparison
ORDER BY users DESC;

WITH pairs AS (
    SELECT user_session,
           LAG(user_session) OVER w AS prev_session,
           date_diff('second', LAG(event_time) OVER w, event_time) / 60.0 AS gap_min
    FROM 'data/parquet/oct.parquet'
    WINDOW w AS (PARTITION BY user_id ORDER BY event_time)
)
SELECT CASE WHEN gap_min < 1   THEN 'a) under 1 min'
            WHEN gap_min < 5   THEN 'b) 1-5 min'
            WHEN gap_min < 10  THEN 'c) 5-10 min'
            WHEN gap_min < 20  THEN 'd) 10-20 min'
            WHEN gap_min < 30  THEN 'e) 20-30 min'
            ELSE                    'f) over 30 min' END AS gap_bucket,
       COUNT(*) AS click_pairs,
       ROUND(100.0 * AVG(CASE WHEN user_session <> prev_session THEN 1 ELSE 0 END), 1)
           AS pct_dataset_split
FROM pairs
WHERE gap_min IS NOT NULL
GROUP BY gap_bucket
ORDER BY gap_bucket;

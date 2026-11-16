-- 02: Data quality checks on October (decisions are recorded in docs/definitions.md).

-- Event mix (view / cart / purchase)
SELECT event_type, COUNT(*) AS n
FROM 'data/parquet/oct.parquet'
GROUP BY event_type
ORDER BY n DESC;

-- Missing values and non-positive prices
SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN category_code IS NULL THEN 1 ELSE 0 END) AS missing_category,
    SUM(CASE WHEN brand IS NULL THEN 1 ELSE 0 END) AS missing_brand,
    SUM(CASE WHEN price <= 0 THEN 1 ELSE 0 END) AS bad_price
FROM 'data/parquet/oct.parquet';

-- Which event types have zero prices? (Result: only views and carts, no purchases.)
SELECT event_type, COUNT(*) AS n,
       MIN(price) AS min_price, MAX(price) AS max_price
FROM 'data/parquet/oct.parquet'
WHERE price <= 0
GROUP BY event_type;

-- Coverage: date range and number of users
SELECT MIN(event_time) AS first_event,
       MAX(event_time) AS last_event,
       COUNT(DISTINCT user_id) AS users
FROM 'data/parquet/oct.parquet';

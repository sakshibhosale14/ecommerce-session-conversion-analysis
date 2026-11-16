-- 01: Convert the raw Kaggle CSVs to Parquet (smaller, much faster to query).
-- Run from the repo root. Put 2019-Oct.csv and 2019-Nov.csv in data/raw/ first.
-- Expected row counts: October 42,448,764; November 67,501,979.

COPY (SELECT * FROM 'data/raw/2019-Oct.csv')
TO 'data/parquet/oct.parquet' (FORMAT PARQUET);

COPY (SELECT * FROM 'data/raw/2019-Nov.csv')
TO 'data/parquet/nov.parquet' (FORMAT PARQUET);

SELECT COUNT(*) AS oct_events FROM 'data/parquet/oct.parquet';
SELECT COUNT(*) AS nov_events FROM 'data/parquet/nov.parquet';

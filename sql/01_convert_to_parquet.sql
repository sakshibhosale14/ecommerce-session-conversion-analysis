-- 01: Convert the raw Kaggle CSVs to Parquet

COPY (SELECT * FROM 'data/raw/2019-Oct.csv')
TO 'data/parquet/oct.parquet' (FORMAT PARQUET);

COPY (SELECT * FROM 'data/raw/2019-Nov.csv')
TO 'data/parquet/nov.parquet' (FORMAT PARQUET);

SELECT COUNT(*) AS oct_events FROM 'data/parquet/oct.parquet';
SELECT COUNT(*) AS nov_events FROM 'data/parquet/nov.parquet';

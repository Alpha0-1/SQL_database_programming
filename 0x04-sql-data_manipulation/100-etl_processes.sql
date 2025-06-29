-- Simple ETL process: extract, transform, load

-- Step 1: Extract from source table
CREATE TEMP TABLE temp_sales AS
SELECT * FROM raw_sales_data;

-- Step 2: Transform
UPDATE temp_sales
SET amount = amount * exchange_rate;

-- Step 3: Load into final table
INSERT INTO fact_sales (sale_id, amount, currency)
SELECT sale_id, amount, 'USD'
FROM temp_sales;

-- Cleanup
DROP TABLE temp_sales;

SELECT 'ETL process completed' AS status;

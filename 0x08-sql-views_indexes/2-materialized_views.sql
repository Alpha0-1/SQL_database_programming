/*
 * Title: Materialized Views
 * Description: Demonstrates how to create and use materialized views
 *
 * Materialized views are physical copies of query results. They:
 * - Provide faster query execution
 * - Require periodic refresh
 * - Are useful for reporting and analytics
 */

-- Step 1: Create a sample table
CREATE TABLE sales (
    sale_id INT PRIMARY KEY,
    product_id INT,
    quantity INT,
    sale_date DATE
);

-- Step 2: Populate sample data
INSERT INTO sales VALUES
    (1, 101, 10, '2023-01-01'),
    (2, 102, 20, '2023-01-02');

-- Step 3: Create a materialized view
CREATE MATERIALIZED VIEW mv_daily_sales AS
SELECT 
    sale_date,
    COUNT(*) AS total_sales,
    SUM(quantity) AS total_quantity
FROM sales
GROUP BY sale_date;

-- Step 4: Refresh the materialized view
REFRESH MATERIALIZED VIEW mv_daily_sales;

-- Step 5: Query the materialized view
SELECT * FROM mv_daily_sales;

/*
 * Explanation:
 * - Materialized views store actual data
 * - They must be explicitly refreshed
 * - Ideal for scenarios where data changes infrequently
 */

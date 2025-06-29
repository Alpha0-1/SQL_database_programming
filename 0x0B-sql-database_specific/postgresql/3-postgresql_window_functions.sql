/*
  Filename: 3-postgresql_window_functions.sql
  Description: PostgreSQL window functions for advanced data analysis
  Author: Alpha0-1
*/

-- Step 1: Connect to the database
\c basic_db;

-- Step 2: Create a table for sales data
CREATE TABLE sales (
    id SERIAL PRIMARY KEY,
    product_name VARCHAR(50),
    sales_amount DECIMAL(10, 2),
    sale_date DATE
);

-- Step 3: Insert sample data
INSERT INTO sales (product_name, sales_amount, sale_date)
VALUES
('Product A', 100, '2023-01-01'),
('Product B', 200, '2023-01-01'),
('Product A', 150, '2023-01-02');

-- Step 4: Use ROW_NUMBER() to rank rows
SELECT 
    product_name, 
    sale_date,
    ROW_NUMBER() OVER (ORDER BY sales_amount DESC) AS row_number
FROM sales;

-- Step 5: Use RANK() and DENSE_RANK()
SELECT 
    product_name, 
    sales_amount,
    RANK() OVER (ORDER BY sales_amount DESC) AS rank,
    DENSE_RANK() OVER (ORDER BY sales_amount DESC) AS dense_rank
FROM sales;

-- Step 6: Use SUM() as a window function
SELECT 
    product_name, 
    sales_amount,
    SUM(sales_amount) OVER (PARTITION BY product_name) AS total_per_product
FROM sales;

/*
  Exercise:
  1. Implement a window function to calculate moving averages
  2. Practice using LAG() and LEAD() functions
  3. Explore different ORDER BY clauses in the OVER() function
*/

-- Cleanup
-- DROP TABLE sales;

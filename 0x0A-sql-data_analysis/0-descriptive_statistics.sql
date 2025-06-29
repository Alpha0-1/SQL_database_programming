-- File: 0-descriptive_statistics.sql
-- Description: Calculate basic descriptive statistics for a dataset

-- Step 1: Create a sample table for demonstration
-- This table simulates a sales dataset with customer transactions
CREATE TABLE IF NOT EXISTS sales (
    id SERIAL PRIMARY KEY,          -- Unique identifier for each sale
    customer_id INT,                -- Foreign key referencing a customer
    amount DECIMAL(10, 2),          -- Sale amount in dollars
    sale_date DATE                  -- Date of sale
);

-- Step 2: Insert sample data for analysis
-- Sample transactions representing different customers and amounts
INSERT INTO sales (customer_id, amount, sale_date)
VALUES 
(1, 100.00, '2023-01-01'),
(2, 150.00, '2023-01-02'),
(3, 200.00, '2023-01-03'),
(4, 50.00,  '2023-01-04'),
(5, 300.00, '2023-01-05');

-- Step 3: Compute descriptive statistics
-- This query gives insight into the distribution and spread of sales amounts
SELECT 
    COUNT(*) AS total_sales,           -- Total number of sales records
    MIN(amount) AS min_amount,         -- Lowest sale amount
    MAX(amount) AS max_amount,         -- Highest sale amount
    AVG(amount) AS average_amount,     -- Mean of all sales
    SUM(amount) AS total_amount,       -- Total revenue from all sales
    STDDEV(amount) AS std_dev_amount,  -- Standard deviation of sale amounts
    VARIANCE(amount) AS variance_amount -- Variance of sale amounts
FROM 
    sales;

-- How to use:
-- Run each step in a SQL environment such as PostgreSQL or MySQL.
-- Use the final SELECT query to perform a descriptive analysis
-- on any numeric column in a similar dataset.


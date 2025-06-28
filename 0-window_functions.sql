-- 0-window_functions.sql
-- Purpose: Demonstrate basic window functions in SQL


-- Sample table creation for demonstration
CREATE TABLE IF NOT EXISTS sales (
    id SERIAL PRIMARY KEY,
    region VARCHAR(50),
    product VARCHAR(100),
    amount NUMERIC(10,2)
);

-- Insert sample data
INSERT INTO sales (region, product, amount) VALUES
('North', 'Laptop', 1200.00),
('South', 'Phone', 800.00),
('North', 'Tablet', 400.00),
('South', 'Laptop', 1100.00),
('East', 'Phone', 750.00);

-- Using ROW_NUMBER to rank sales within each region by amount
SELECT
    region,
    product,
    amount,
    ROW_NUMBER() OVER (PARTITION BY region ORDER BY amount DESC) AS row_num
FROM sales;

-- Using RANK and DENSE_RANK
SELECT
    region,
    product,
    amount,
    RANK() OVER (ORDER BY amount DESC) AS rank,
    DENSE_RANK() OVER (ORDER BY amount DESC) AS dense_rank
FROM sales;

-- Clean up (optional)
-- DROP TABLE sales;

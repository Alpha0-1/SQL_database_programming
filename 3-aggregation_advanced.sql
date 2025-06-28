-- File: 3-aggregation_advanced.sql
-- Description: Advanced GROUP BY techniques and aggregation patterns
-- Author: Alpha0-1
-- Date: 2025

-- Advanced aggregation goes beyond basic GROUP BY to include
-- ROLLUP, CUBE, GROUPING SETS, and complex aggregation scenarios

-- Sample data: Sales transactions
CREATE TABLE IF NOT EXISTS sales_transactions (
    transaction_id INT PRIMARY KEY,
    product_category VARCHAR(50),
    product_name VARCHAR(100),
    customer_region VARCHAR(50),
    customer_segment VARCHAR(50),
    sale_date DATE,
    quantity INT,
    unit_price DECIMAL(10,2),
    discount_percent DECIMAL(5,2)
);

INSERT INTO sales_transactions VALUES
(1, 'Electronics', 'Laptop', 'North', 'Corporate', '2024-01-15', 2, 1200.00, 5.0),
(2, 'Electronics', 'Mouse', 'North', 'Corporate', '2024-01-16', 5, 25.00, 0.0),
(3, 'Electronics', 'Laptop', 'South', 'Consumer', '2024-01-17', 1, 1200.00, 10.0),
(4, 'Furniture', 'Desk', 'North', 'Corporate', '2024-01-18', 3, 400.00, 15.0),
(5, 'Furniture', 'Chair', 'East', 'Consumer', '2024-01-19', 4, 150.00, 5.0),
(6, 'Electronics', 'Keyboard', 'South', 'Corporate', '2024-01-20', 3, 75.00, 0.0),
(7, 'Furniture', 'Desk', 'West', 'Consumer', '2024-01-21', 1, 400.00, 20.0),
(8, 'Electronics', 'Monitor', 'North', 'Consumer', '2024-01-22', 2, 300.00, 8.0),
(9, 'Furniture', 'Chair', 'South', 'Corporate', '2024-01-23', 6, 150.00, 12.0),
(10, 'Electronics', 'Tablet', 'East', 'Consumer', '2024-01-24', 1, 500.00, 5.0);

-- 1. Basic aggregation with multiple grouping levels
SELECT 
    product_category,
    customer_region,
    customer_segment,
    COUNT(*) as transaction_count,
    SUM(quantity) as total_quantity,
    SUM(quantity * unit_price * (1 - discount_percent/100)) as total_revenue,
    AVG(unit_price) as avg_unit_price,
    MIN(sale_date) as first_sale,
    MAX(sale_date) as last_sale
FROM sales_transactions
GROUP BY product_category, customer_region, customer_segment
ORDER BY product_category, customer_region, customer_segment;

-- 2. ROLLUP - Creates subtotals at each level of grouping
-- Generates subtotals for each level of the hierarchy
SELECT 
    product_category,
    customer_region,
    COUNT(*) as transaction_count,
    SUM(quantity * unit_price * (1 - discount_percent/100)) as total_revenue,
    -- GROUPING function helps identify which rows are subtotals
    GROUPING(product_category) as cat_grouping,
    GROUPING(customer_region) as region_grouping
FROM sales_transactions
GROUP BY ROLLUP(product_category, customer_region)
ORDER BY 
    GROUPING(product_category),
    product_category,
    GROUPING(customer_region),
    customer_region;

-- 3. CUBE - Creates subtotals for all possible combinations
-- More comprehensive than ROLLUP, includes cross-tabulations
SELECT 
    product_category,
    customer_segment,
    COUNT(*) as transaction_count,
    SUM(quantity * unit_price * (1 - discount_percent/100)) as total_revenue,
    -- Label the different grouping levels
    CASE 
        WHEN GROUPING(product_category) = 1 AND GROUPING(customer_segment) = 1 
        THEN 'Grand Total'
        WHEN GROUPING

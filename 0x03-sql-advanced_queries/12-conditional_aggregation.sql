-- 12-conditional_aggregation.sql
-- Purpose: Demonstrate conditional aggregation
-- Author: Alpha0-1

-- Sales data by category
CREATE TABLE IF NOT EXISTS sales_by_category (
    category VARCHAR(50),
    amount NUMERIC(10,2)
);

-- Insert sample data
INSERT INTO sales_by_category (category, amount) VALUES
('Electronics', 1000),
('Clothing', 800),
('Electronics', 1500),
('Clothing', 600);

-- Conditional aggregation to separate categories
SELECT
    SUM(CASE WHEN category = 'Electronics' THEN amount ELSE 0 END) AS electronics_sales,
    SUM(CASE WHEN category = 'Clothing' THEN amount ELSE 0 END) AS clothing_sales
FROM sales_by_category;

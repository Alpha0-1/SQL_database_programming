-- File: 100-advanced_tuning.sql
-- Topic: Advanced tuning techniques
-- Description: Advanced SQL performance optimization techniques

/*
 * Advanced SQL Performance Tuning
 *
 * This file demonstrates advanced techniques for optimizing SQL performance
 */

-- Example 1: Fine-tuning query planning
-- Using the planner to avoid bad estimates
SET enable_hashjoin = off;
SET enable_mergejoin = on;

-- Example 2: Using parallel query effectively
SET max_parallel_workers_per_gather = 4;

-- Example 3: Using CTAS (Create Table As Select)
CREATE TABLE sales_summary AS
SELECT date_trunc('month', order_date) as month, SUM(order_total) as total_sales
FROM orders
GROUP BY month;

-- Example 4: Using query hints
-- Not natively supported in PostgreSQL, but can be simulated using table aliases
SELECT /*+ gather_plan index Scan(PKIndexPath) */ * FROM orders;

-- Example 5: Using index-only scans
CREATE INDEX idx_order_total ON orders(order_total);
EXPLAIN SELECT COUNT(order_total) FROM orders WHERE order_total > 1000;

-- Example 6: Using unlogged tables for temporary data
CREATE UNLOGGED TABLE temp_sales (
    sale_id INT,
    sale_date DATE,
    sale_amount DECIMAL
);

-- Example 7: Using GIN indexes for complex queries
CREATE INDEX idx_text_search ON documents USING GIN (to_tsvector('english', content));

-- Example 8: Using PostgreSQL hints via pg_hint_plan
-- This requires the pg_hint_plan extension
SELECT /*+ indexScan(users pk_users) */ * FROM users WHERE user_id = 1;

-- Example 9: Monitoring and tuning database parameters
SELECT name, setting, unit FROM pg_settings 
WHERE category = 'Performance' 
ORDER BY name;

-- Example 10: Custom bounding box optimizations
-- Example of bounding box optimization for spatial queries
SELECT * FROM locations WHERE ST_contains(geom, ST_MakePoint(10, 10));

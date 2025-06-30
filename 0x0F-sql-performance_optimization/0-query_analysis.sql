-- File: 0-query_analysis.sql
-- Topic: Query performance analysis
-- Description: Examples of analyzing query performance using EXPLAIN and performance monitoring tools

/*
 * Performance Analysis Examples
 * 
 * These examples demonstrate how to analyze query performance
 * using EXPLAIN and other performance monitoring techniques
 */

-- Example 1: Basic EXPLAIN usage
EXPLAIN SELECT * FROM orders WHERE order_date >= '2023-01-01';

-- Example 2: Verbose EXPLAIN output
EXPLAIN VERBOSE SELECT * FROM customers c JOIN orders o USING(customer_id);

-- Example 3: Using EXPLAIN ANALYZE to measure performance
EXPLAIN ANALYZE
SELECT product_name, SUM(quantity) as total_sold
FROM products p 
JOIN order_items oi USING(product_id)
WHERE order_date >= '2023-01-01'
GROUP BY product_name;

-- Example 4: Identifying performance bottlenecks
-- This query will show high cost if no index on order_date
EXPLAIN SELECT * FROM orders WHERE order_date >= '2023-01-01';

-- Example 5: Measuring query execution time directly
\timing on
SELECT COUNT(*) FROM large_table;
\timing off

-- Example 6: Checking query statistics
SELECT * FROM pg_stat_activity;
SELECT * FROM pg_stat_user_tables;
SELECT * FROM pg_stat_user_indexes;

-- Example 7: Identifying long-running queries
SELECT pid, age(query_start), usename, query
FROM pg_stat_activity
WHERE state = 'active'
ORDER BY age(query_start) DESC;

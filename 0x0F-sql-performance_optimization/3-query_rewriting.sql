-- File: 3-query_rewriting.sql
-- Topic: Query rewriting techniques
-- Description: Examples of optimizing queries through rewriting

/*
 * Query Rewriting Examples
 *
 * This file demonstrates different SQL query optimization techniques
 */

-- Example 1: Using JOIN instead of subqueries
-- Poor performing subquery version
SELECT * FROM customers 
WHERE customer_id IN (SELECT customer_id FROM orders WHERE order_date >= '2023-01-01');

-- Optimized JOIN version
SELECT * FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_date >= '2023-01-01';

-- Example 2: Avoiding SELECT *
-- Use specific columns instead
SELECT customer_name, total_orders FROM customer_stats;

-- Example 3: Using proper join conditions
-- Always use proper join conditions with foreign keys
SELECT * FROM orders o
JOIN customers c ON o.customer_id = c.customer_id;

-- Example 4: Limiting results early
SELECT * FROM large_table
WHERE some_column = 'value'
ORDER BY id DESC
LIMIT 10;

-- Example 5: Using WITH clause for complex queries
WITH recent_orders AS (
    SELECT * FROM orders WHERE order_date >= '2023-01-01'
)
SELECT COUNT(*) FROM recent_orders;

-- Example 6: Using materialized views
CREATE MATERIALIZED VIEW sales_summary
AS SELECT date_trunc('month', order_date) as month, SUM(order_total) as total_sales
FROM orders GROUP BY month;

-- Example 7: Avoiding correlated subqueries
-- Correlated subquery version
SELECT customer_name,
(SELECT COUNT(*) FROM orders o WHERE o.customer_id = c.customer_id) as order_count
FROM customers c;

-- Optimized using JOIN
SELECT c.customer_name, COUNT(o.order_id) as order_count
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_name;

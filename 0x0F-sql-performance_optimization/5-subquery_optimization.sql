-- File: 5-subquery_optimization.sql
-- Topic: Subquery optimization
-- Description: Techniques for optimizing subqueries

/*
 * Subquery Optimization Examples
 *
 * This file demonstrates how to optimize subqueries and improve performance
 */

-- Example 1: Using EXISTS instead of IN
-- Poor performing IN version
SELECT * FROM customers
WHERE customer_id IN (SELECT customer_id FROM orders WHERE order_date >= '2023-01-01');

-- Optimized EXISTS version
SELECT * FROM customers c
WHERE EXISTS (
    SELECT 1 FROM orders o WHERE o.customer_id = c.customer_id
    AND o.order_date >= '2023-01-01'
);

-- Example 2: Using JOIN instead of subqueries
-- Poor performing subquery version
SELECT * FROM products
WHERE product_id IN (SELECT product_id FROM order_items);

-- Optimized JOIN version
SELECT p.* FROM products p
JOIN order_items oi ON p.product_id = oi.product_id;

-- Example 3: Using CTE for complex subqueries
WITH recent_orders AS (
    SELECT * FROM orders WHERE order_date >= '2023-01-01'
)
SELECT COUNT(*) FROM recent_orders;

-- Example 4: Avoiding correlated subqueries
-- Correlated subquery version
SELECT customer_name,
    (SELECT COUNT(*) FROM orders o WHERE o.customer_id = c.customer_id) as order_count
FROM customers c;

-- Optimized version
SELECT c.customer_name, COUNT(o.order_id) as order_count
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_name;

-- Example 5: Indexing columns used in subqueries
CREATE INDEX idx_order_customer_id ON orders(customer_id);

-- Example 6: Using derived tables
SELECT * FROM (
    SELECT product_name, SUM(quantity) as total_sold
    FROM order_items
    GROUP BY product_name
) AS product_sales
WHERE total_sold > 100;

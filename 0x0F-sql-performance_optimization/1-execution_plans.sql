-- File: 1-execution_plans.sql
-- Topic: Reading execution plans
-- Description: Understanding and interpreting SQL execution plans

/*
 * Understanding Execution Plans
 *
 * This example demonstrates how to interpret different types of execution plans
 */

-- Example 1: Nested Loop Join execution plan
EXPLAIN SELECT * FROM customers c JOIN orders o ON c.customer_id = o.customer_id;

-- Example 2: Merge Join execution plan
-- Create index first
CREATE INDEX idx_customer_id ON customers(customer_id);
CREATE INDEX idx_order_customer_id ON orders(customer_id);

-- Now check execution plan
EXPLAIN SELECT * FROM customers c JOIN orders o ON c.customer_id = o.customer_id;

-- Example 3: Hash Join execution plan
-- For large tables
EXPLAIN SELECT * FROM orders o JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_date >= '2023-01-01';

-- Example 4: Index Scan vs Seq Scan
-- For sequential scan
EXPLAIN SELECT * FROM products WHERE product_name LIKE 'Smart%';

-- For index scan (after creating index)
CREATE INDEX idx_product_name ON products(product_name);
EXPLAIN SELECT * FROM products WHERE product_name LIKE 'Smart%';

-- Example 5: Cartesian product warning
EXPLAIN SELECT * FROM customers c, orders o
WHERE c.customer_id = o.customer_id;

-- 100-query_optimization.sql
-- Purpose: Demonstrate query optimization techniques
-- Author: Alpha0-1

-- Use indexes wisely
CREATE INDEX idx_customer_id ON orders(customer_id);

-- Avoid SELECT *
EXPLAIN ANALYZE
SELECT name FROM customers WHERE id = 1;

-- Use LIMIT when possible
SELECT * FROM sales LIMIT 10;

-- Use EXISTS instead of IN where appropriate
SELECT * FROM customers c
WHERE EXISTS (
    SELECT 1 FROM orders o WHERE o.customer_id = c.id
);

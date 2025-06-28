-- 102-performance_tuning.sql
-- Purpose: Performance tuning examples
-- Author: Alpha0-1

-- Use proper indexing
CREATE INDEX idx_order_customer_id ON orders(customer_id);

-- Vacuum and analyze for statistics
VACUUM ANALYZE customers;

-- Rewrite inefficient queries
-- Instead of:
-- SELECT * FROM customers WHERE id NOT IN (SELECT customer_id FROM orders)

-- Better use:
SELECT * FROM customers c
WHERE NOT EXISTS (
    SELECT 1 FROM orders o WHERE o.customer_id = c.id
);

-- Monitor performance using pg_stat_statements if available
-- SELECT * FROM pg_stat_statements ORDER BY total_time DESC LIMIT 10;

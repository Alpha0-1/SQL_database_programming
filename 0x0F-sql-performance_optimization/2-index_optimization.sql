-- File: 2-index_optimization.sql
-- Topic: Index optimization
-- Description: Examples of creating and optimizing indexes

/*
 * Index Optimization Examples
 *
 * This file demonstrates different index optimization techniques
 */

-- Example 1: Creating a simple index
CREATE INDEX idx_customer_name ON customers(customer_name);

-- Example 2: Creating a composite index
CREATE INDEX idx_order_date ON orders(order_date, order_total);

-- Example 3: Covering index
-- Index includes all columns needed by query
CREATE INDEX idx_order_summary ON orders(order_date, order_total, customer_id);

-- Example 4: Partial index
CREATE INDEX idx_order_previous_year
ON orders(order_date, order_total)
WHERE order_date >= '2022-01-01';

-- Example 5: Index with proper data types
CREATE INDEX idx_product_price ON products(product_price numeric);

-- Example 6: Index on frequently filtered columns
-- Note: Avoid indexing columns with low cardinality

-- Example 7: Maintaining indexes
REINDEX INDEX idx_customer_name;

-- Example 8: Dropping indexes that are no longer needed
DROP INDEX idx_unneeded;

-- Example 9: Monitoring index usage
SELECT * FROM pg_stat_indexes;

-- Example 10: Identifying missing indexes
-- Using auto_explain or other monitoring tools

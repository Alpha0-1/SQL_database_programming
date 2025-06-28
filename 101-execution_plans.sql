-- 101-execution_plans.sql
-- Purpose: Analyze execution plans
-- Author: Alpha0-1

-- Enable timing
\timing on

-- Get execution plan for a query
EXPLAIN ANALYZE
SELECT * FROM customers WHERE id = 1;

-- Use verbose option
EXPLAIN VERBOSE
SELECT name FROM customers WHERE id = 1;

-- Join performance analysis
EXPLAIN ANALYZE
SELECT * FROM customers c
JOIN orders o ON c.id = o.customer_id;

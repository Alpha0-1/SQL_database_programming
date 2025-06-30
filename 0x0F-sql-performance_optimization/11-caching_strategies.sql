-- File: 11-caching_strategies.sql
-- Topic: Caching strategies
-- Description: Examples of caching strategies in SQL

/*
 * Caching Strategies Examples
 *
 * This file demonstrates different caching strategies to improve performance
 */

-- Example 1: Using PostgreSQL query cache
-- Enable by setting appropriate configurations
SET query_cache_size = 100MB;

-- Example 2: Caching at the application level
-- Use Redis or Memcached for frequently accessed data

-- Example 3: Using materialized views for reporting
CREATE MATERIALIZED VIEW sales_summary AS
SELECT date_trunc('month', order_date) as month, SUM(order_total) as total_sales
FROM orders
GROUP BY month;

-- Example 4: Caching aggregations
-- Instead of recalculating every time
SELECT * FROM sales_summary
WHERE month = '2023-01-01';

-- Example 5: Using ETL processes for caching
-- Load aggregated data into separate tables periodically

-- Example 6: Monitoring cache usage
SELECT 
    sum(heap_blks_hit) / sum(heap_blks_hit + heap_blks_read) * 100 AS cache_hit_rate
FROM 
    pg_statio_user_tables;

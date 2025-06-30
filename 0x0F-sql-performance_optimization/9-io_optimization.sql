-- File: 9-io_optimization.sql
-- Topic: I/O optimization
-- Description: Examples of optimizing disk I/O operations

/*
 * I/O Optimization Examples
 *
 * This file demonstrates how to optimize disk I/O operations
 */

-- Example 1: Using appropriate storage engines
-- Use SSDs for tables with high read/write activity

-- Example 2: Minimizing disk operations
-- Prioritize in-memory operations where possible

-- Example 3: Using sequential scans
-- Sequential scans are faster than random access for large sequential data

-- Example 4: Monitoring disk I/O
SELECT * FROM pg_stat_user_tables 
ORDER BY heap_blks_read DESC;

-- Example 5: Reducing I/O by using indexes
CREATE INDEX idx_order_date ON orders(order_date);

-- Example 6: Check I/O performance
\timing on
SELECT COUNT(*) FROM large_table;
\timing off

-- Example 7: Setting appropriate buffer cache sizes
-- Adjust shared_buffers based on system resources
ALTER SYSTEM SET shared_buffers = '1G';

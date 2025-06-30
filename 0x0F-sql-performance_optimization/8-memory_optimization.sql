-- File: 8-memory_optimization.sql
-- Topic: Memory usage optimization
-- Description: Techniques for optimizing memory usage

/*
 * Memory Optimization Examples
 *
 * This file demonstrates how to optimize memory usage in SQL operations
 */

-- Example 1: Adjusting work_mem setting
-- Recommendations:
-- - On small systems: 64MB
-- - On large systems: 512MB or more
SET work_mem = '64MB';

-- Example 2: Using appropriate data types
-- Use smaller data types where possible
CREATE TABLE small_table (
    id INT,
    name CHAR(50),
    price DECIMAL(10,2)
);

-- Example 3: Minimizing memory usage in queries
-- Avoid heavy use of row-oriented data
SELECT COUNT(*) FROM large_table WHERE column = 'value';

-- Example 4: Using hash-based operations when possible
-- Tunnel INTO hash joins when data is scattered

-- Example 5: Monitoring memory usage
SELECT * FROM pg_memory_context_stats();
SELECT * FROM pg_stat_activity 
WHERE usename = 'current_user';

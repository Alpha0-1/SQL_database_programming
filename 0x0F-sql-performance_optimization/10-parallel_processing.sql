-- File: 10-parallel_processing.sql
-- Topic: Parallel query processing
-- Description: Examples of using parallel query execution

/*
 * Parallel Processing Examples
 *
 * This file demonstrates how to leverage parallel query processing
 */

-- Example 1: Enabling parallel query
SET max_parallel_workers_per_gather = 4;

-- Example 2: Check if a query is using parallelism
EXPLAIN SELECT * FROM large_table
WHERE column = 'value';

-- Example 3: Using parallel sequential scans
-- Enable with proper configuration
SET parallel_seq_scan = on;

-- Example 4: Testing parallel query performance
\_timing ON
SELECT COUNT(*) FROM large_table;
\_timing OFF

-- Example 5: Monitoring parallel workers
SELECT 
    pid, 
    datname, 
    usename, 
    query 
FROM pg_stat_activity 
WHERE query LIKE 'GATHER%';

-- Example 6: Configuring parallel settings
-- Adjust according to system resources
SET max_parallel_workers = 8;
SET parallel_tuple_cost = 0.1;

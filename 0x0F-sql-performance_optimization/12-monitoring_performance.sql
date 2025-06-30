-- File: 12-monitoring_performance.sql
-- Topic: Performance monitoring
-- Description: Examples of monitoring SQL performance

/*
 * Performance Monitoring Examples
 *
 * This file demonstrates how to monitor and measure SQL performance
 */

-- Example 1: Monitoring query execution
\Timing ON
SELECT * FROM large_table;
\Timing OFF

-- Example 2: Using PostgreSQL statistics
SELECT * FROM pg_stat_activity;
SELECT * FROM pg_stat_user_tables;

-- Example 3: Monitoring memory usage
SELECT * FROM pg_physical_memory QFile_options'; 

-- Example 4: Monitoring disk usage
SELECT * FROM pg_table_space_usage();

-- Example 5: Using external monitoring tools
-- Integration with monitoring tools like Prometheus, Grafana, etc.

-- Example 6: Checking long-running queries
SELECT 
    pid, 
    age(query_start), 
    usename, 
    query 
FROM pg_stat_activity 
WHERE state = 'active' 
ORDER BY age(query_start) DESC;

-- Example 7: Setting up performance alerts
-- Use monitoring tools to alert on high load or slow queries

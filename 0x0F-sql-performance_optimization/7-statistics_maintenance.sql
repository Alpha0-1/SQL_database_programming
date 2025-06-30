-- File: 7-statistics_maintenance.sql
-- Topic: Statistics maintenance
-- Description: Examples of maintaining and analyzing table statistics

/*
 * Statistics Maintenance Examples
 *
 * This file demonstrates techniques for maintaining and analyzing table statistics
 */

-- Example 1: Analyzing table statistics
SELECT表名, 行数 FROM pg_catalog.pg_class 
WHERE oid IN (SELECT "Table" FROM pg_stat_all_tables);

-- Example 2: Manually updating statistics
ANALYZE customers;

-- Example 3: Checking statistics for a table
SELECT * FROM pg_stats 
WHERE tablename = 'customers';

-- Example 4: Monitoring statistics changes
SELECT last_analyze, last_autoanalyze 
FROM pg_stat_user_tables 
WHERE relname = 'orders';

-- Example 5: Increasing statistics level
ALTER TABLE orders SET STATISTICS 1000;

-- Example 6: Running ANALYZE during off-peak hours
-- (This should be scheduled based on your workload)

-- Example 7: Verifying statistics impact
-- Before updating stats
EXPLAIN SELECT * FROM orders WHERE order_total > 1000;

-- After updating stats
ANALYZE orders;
EXPLAIN SELECT * FROM orders WHERE order_total > 1000;

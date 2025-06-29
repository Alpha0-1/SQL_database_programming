-- 101-health_checks.sql
-- Purpose: Perform regular database health checks

-- Check if the database is accepting connections
SELECT version();

-- Check for long-running transactions that may cause bloat
SELECT pid, usename, now() - query_start AS duration, query
FROM pg_stat_statements
WHERE now() - query_start > interval '5 minutes'
ORDER BY duration DESC;

-- Check for missing indexes
SELECT relname AS table_name
FROM pg_stat_user_tables
WHERE n_live_tup > 1000 AND idx_scan = 0;

-- Check for unused indexes
SELECT indexrelname AS index_name, relname AS table_name
FROM pg_stat_all_indexes
WHERE idx_scan = 0 AND schemaname = 'public';

-- Check disk space usage
SELECT pg_size_pretty(pg_database_size(current_database()));

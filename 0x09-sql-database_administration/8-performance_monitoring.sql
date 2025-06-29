/*
** Topic: Performance Monitoring
** Description: Examples of monitoring database performance.
** Learning Objectives:
**   1. Use DMVs for performance analysis
**   2. Identify performance bottlenecks
**   3. Optimize queries
*/

-- Get top 10 most resource-intensive queries
SELECT 
    TOP 10 
    total_worker_time / 1000000 as total_CPU_millisecs,
    execution_count,
    totalLogicalReads = total_logical_reads,
    statement = SUBSTRING(text, statement_start_offset/2 +1, 
    (CASE WHEN statement_end_offset IS NULL THEN LEN(text) ELSE statement_end_offset/2 END - statement_start_offset/2)),
    query_hash
FROM 
    sys.dm_exec_query_stats AS qs
CROSS APPLY 
    sys.dm_exec_sql_text(qs.sql_handle) AS st
ORDER BY 
    total_worker_time DESC;

-- Identify wait statistics
SELECT 
    wait_type,
    wait_time_ms,
    signal_wait_time_ms,
    (wait_time_ms - signal_wait_time_ms) as resource_wait_time_ms,
    waiting_tasks_count
FROM 
    sys.dm_os_wait_stats
WHERE 
    wait_type NOT IN ('WAITForResource', 'WAITfordbcheckpoint', 'WAITforContinuedAccess')
ORDER BY 
    wait_time_ms DESC;

-- Best practices:
-- Regularly review performance metrics
-- Optimize frequently run queries
-- Use index tuning to improve performance

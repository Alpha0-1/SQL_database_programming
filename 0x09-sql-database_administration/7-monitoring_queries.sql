/*
** Topic: System Monitoring
** Description: Examples of monitoring database and system health.
** Learning Objectives:
**   1. Monitor database connections
**   2. Identify blocking processes
**   3. Check system resources
*/

-- View current database connections
SELECT 
    session_id,
    login_name,
    database_name,
    host_name,
    start_time,
    status
FROM sys.dm_exec_sessions;

-- Identify blocking processes
SELECT 
    blocking_session_id,
    wait_type,
    wait_duration_ms
FROM sys.dm_exec_locks;

-- Check CPU usage
SELECT 
    total_CPU,
    @timestamp AS current_time,
    CAST(total_CPU * 100.0 / ( (cpu_ticks / 1000) - previous_cpu_ticks ) AS DECIMAL(10,2)) AS [CPU Utilization (%)],
    dateadd(second, - ( (cpu_ticks / 1000) - previous_cpu_ticks ), getdate()) AS [Start Time]
FROM sys.dm_os_performance_counters
WHERE counter_name = 'CPU usage percentage';

-- Best practices:
-- Regularly monitor for performance issues
-- Set up alerts for critical conditions
-- Use appropriate monitoring tools

-- Filename: 101-monitoring_locks.sql
-- Description: Monitoring database locks to identify contention and bottlenecks.

/*
NOTES:
- Lock contention is a common source of performance issues.
- MySQL provides several ways to monitor locks and transactions.

PREREQUISITES:
- Access to the information_schema database.
*/

/*
Query 1: View current locks in the database
*/

SELECT 
    t.id AS thread_id,
    r.table_name,
    r.lock_type,
    r.lock_mode,
    r.lock_status,
    t.query AS sql_query
FROM 
    information_schema.innodb_locks l
JOIN 
    information_schema.innodb_lock_waits w ON l.lock_id = w.lock_id
JOIN 
    information_schema.innodb_trx t ON w.trx_id = t.trx_id
JOIN 
    information_schema.innodb_tables r ON t.trx_id = r.trx_id;

/*
Query 2: View active transactions and their locks
*/

SELECT 
    trx_id AS transaction_id,
    trx_state AS state,
    trx隔离_level AS isolation_level,
    trx_started AS started,
    trx_tables AS tables,
    trx_locks AS locks,
    trx_rows_locked AS rows_locked
FROM 
    information_schema.innodb_trx;

/*
Query 3: View lock waits (deadlocks)
*/

SELECT 
    r.trx_id AS waiting_trx_id,
    r.lock_type AS waiting_type,
    r.lock_mode AS waiting_mode,
    r.lock_table AS waiting_table,
    b.trx_id AS blocking_trx_id,
    b.lock_type AS blocking_type,
    b.lock_mode AS blocking_mode,
    b.lock_table AS blocking_table
FROM 
    information_schema.innodb_lock_waits w
JOIN 
    information_schema.innodb_locks r ON w.requested_lock_id = r.lock_id
JOIN 
    information_schema.innodb_locks b ON w.blocking_lock_id = b.lock_id;

/*
TIPS:
- Regularly monitor lock contention using these queries.
- Identify long-running transactions that may be causing bottlenecks.
- Optimize queries to reduce lock contention.
*/

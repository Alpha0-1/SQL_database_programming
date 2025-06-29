-- Filename: 102-troubleshooting.sql
-- Description: Troubleshooting common transaction and concurrency issues.

/*
NOTES:
- Common issues include deadlocks, timeouts, and long-running transactions.
- Use the information_schema and performance_schema to diagnose problems.

PREREQUISITES:
- Database with active transactions.
*/

/*
Scenario 1: Detecting Deadlocks
*/

SELECT 
    e.event_id,
    e.source,
    e.query,
    e.timestamp
FROM 
    performance_schema.events_transaction_error e
WHERE 
    e.error_type = ' deadlock ';

/*
Scenario 2: Identifying Long-Running Transactions
*/

SELECT 
    trx_id AS transaction_id,
    trx_state AS state,
    trx_started AS started,
    trx_locks AS locks,
   trx_rows_locked AS rows_locked
FROM 
    information_schema.innodb_trx
WHERE 
    trx_state = 'RUNNING' AND 
    timediff(NOW(), trx_started) > '00:00:10';  -- Transactions running longer than 10 seconds

/*
Scenario 3: Diagnosing Lock Contention
*/

SELECT 
    l.lock_table,
    l.lock_type,
    l.lock_mode,
    t.trx_state,
    t.trx_query
FROM 
    information_schema.innodb_locks l
JOIN 
    information_schema.innodb_trx t ON l.trx_id = t.trx_id
WHERE 
    l.lock_status = 'waiting';

/*
Solutions:
1. Optimize queries to reduce lock duration.
2. Use appropriate isolation levels.
3. Break down large transactions into smaller ones.
4. Use row-level locking where possible.
5. Implement retry logic for deadlocks.
*/

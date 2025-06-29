-- Filename: 12-two_phase_commit.sql
-- Description: Demonstrating the Two-Phase Commit (2PC) protocol in a distributed transaction.

/*
NOTES:
- Two-Phase Commit (2PC) is a protocol used in distributed databases to ensure atomicity across multiple nodes.
- It involves two phases: Prepare Phase and Commit Phase.

PREREQUISITES:
- Ensure two databases are set up (e.g., db1 and db2) with innodb table engines.
- Each database should have a table to represent a participating resource.
*/

START TRANSACTION;

-- Step 1: Perform operations on database 1
USE db1;
INSERT INTO table1 (id, name) VALUES (1, 'Alice');
SET @db1_result = LAST_INSERT_ID();

-- Step 2: Perform operations on database 2
USE db2;
INSERT INTO table2 (id, name) VALUES (1, 'Alice');
SET @db2_result = LAST_INSERT_ID();

-- Step 3: Prepare Phase
-- Check if both databases are ready to commit
SELECT 
    CASE 
        WHEN @db1_result > 0 AND @db2_result > 0 THEN 'COMMIT'
        ELSE 'ROLLBACK'
    END AS decision;

-- Step 4: Commit Phase
-- Based on the decision from the prepare phase, commit or rollback
COMMIT;  -- Replace with ROLLBACK if decision is ROLLBACK

/*
TIPS:
- In a real distributed system, the coordinator node (this session) would communicate with
  each participant (db1 and db2) to request their readiness.
- The commit phase is irreversible once started; participants must either commit or rollback.
- 2PC can lead to performance overhead due to the additional round-trip in the prepare phase.
*/

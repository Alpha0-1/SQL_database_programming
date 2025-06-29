-- 4-deadlock_handling.sql
-- This script demonstrates how to handle deadlocks in SQL transactions

-- Step 1: Understanding Deadlocks
-- A deadlock occurs when two or more transactions are waiting for each other to release locks
-- which they can never do because they are also waiting. This creates a cycle of waiting.

-- Step 2: Scenario Setup
-- We are using a simple database with tables 'employees' and 'departments'
-- Both tables are manipulated by multiple transactions

-- Step 3: Creating Test Data
-- Creating a test database with sample tables to demonstrate deadlocks
-- Create Sample Tables
CREATE TABLE employees (
    emp_id INT PRIMARY KEY,
    emp_name VARCHAR(100),
    dept_id INT,
    salary DECIMAL(10,2)
);

CREATE TABLE departments (
    dept_id INT PRIMARY KEY,
    dept_name VARCHAR(100),
    budget DECIMAL(10,2)
);

-- Insert Sample Data
INSERT INTO employees VALUES (1, 'Alice', 1, 50000);
INSERT INTO employees VALUES (2, 'Bob', 2, 55000);

INSERT INTO departments VALUES (1, 'HR', 100000);
INSERT INTO departments VALUES (2, 'Finance', 200000);

-- Step 4: Simulating Deadlock Conditions
-- Transaction 1: Updates employees and then departments
START TRANSACTION;
UPDATE employees SET salary = 51000 WHERE emp_id = 1;
-- Hangs to simulate concurrent access
-- Placeholder for commit
COMMIT;

-- Transaction 2: Updates departments and then employees
START TRANSACTION;
UPDATE departments SET budget = 98000 WHERE dept_id = 1;
-- Hangs to simulate concurrent access
-- Placeholder for commit
COMMIT;

-- Step 5: Detecting and Resolving Deadlocks
-- Most DBMS automatically detect deadlocks and abort one transaction to resolve the deadlock
-- SQL can use lock timeouts or specific deadlock detection commands

-- Example to set deadlock_timeout in PostgreSQL
-- This is a configuration setting and not part of transaction SQL
-- ALTER SYSTEM SET deadlock_timeout = '1s';

-- Step 6: Preventing Deadlocks
-- Best Practices
-- 1. Always access objects in the same order
-- 2. Keep transactions short and avoid long-running transactions
-- 3. Use row-level locking instead of table-level locking
-- 4. Reduce lock contention by optimizing queries
-- 5. ImplementRetry Logic for Deadlock Encounters

-- Example: Using SELECT ... FOR UPDATE to lock specific rows
-- This ensures that only specific rows are locked, reducing contention
START TRANSACTION;
-- Lock specific employee and department
SELECT * FROM employees WHERE emp_id = 1 FOR UPDATE;
SELECT * FROM departments WHERE dept_id = 1 FOR UPDATE;

-- Perform updates
UPDATE employees SET salary = 52000 WHERE emp_id = 1;
UPDATE departments SET budget = 97000 WHERE dept_id = 1;

COMMIT;

-- Step 7: Cleanup Test Data
-- Drop the sample tables after testing
DROP TABLE employees;
DROP TABLE departments;

-- Step 8: Notes
-- - Deadlocks are inevitable in multi-user environments
-- - Proper transaction management and lock handling are critical
-- - Understanding the database's deadlock detection mechanism is essential
-- - Always test for deadlocks in a controlled environment

-- Filename: 9-race_conditions.sql  
-- Topic: Avoiding Race Conditions  
-- Description: Demonstrates techniques to prevent race conditions in concurrent updates  

-- SET UP TEST ENVIRONMENT  
-- Create a test database and table  
CREATE DATABASE IF NOT EXISTS race_condition_demo;  
USE race_condition_demo;  

-- Create a sample table simulating account transfers  
CREATE TABLE IF NOT EXISTS accounts (  
    account_id INT AUTO_INCREMENT PRIMARY KEY,  
    account_name VARCHAR(50),  
    balance DECIMAL(10,2)  
);  

-- Insert sample data  
INSERT INTO accounts (account_name, balance)  
VALUES ('Alice', 1000.00),  
       ('Bob', 500.00);  

-- Demonstrate a potential race condition: transfer from Alice to Bob  
SET autocommit = 0;  

-- Simulate two concurrent transactions:  
-- Transaction 1 (Transfer $100 from Alice to Bob)  
START TRANSACTION;  
    SELECT balance FROM accounts WHERE account_name = 'Alice';  
    UPDATE accounts SET balance = balance - 100 WHERE account_name = 'Alice';  
    -- Simulate delay (e.g., another transaction starts here)  
    UPDATE accounts SET balance = balance + 100 WHERE account_name = 'Bob';  
COMMIT;  

-- Transaction 2 (Transfer $50 from Alice to Bob)  
START TRANSACTION;  
    SELECT balance FROM accounts WHERE account_name = 'Alice';  
    UPDATE accounts SET balance = balance - 50 WHERE account_name = 'Alice';  
    UPDATE accounts SET balance = balance + 50 WHERE account_name = 'Bob';  
COMMIT;  

-- Check the final balances  
SELECT * FROM accounts;  

-- Discussion:  
-- Without proper handling, the balances might not reflect the correct total due to interleaving updates  
-- Let's see the result  
SELECT balance FROM accounts WHERE account_name = 'Alice';  
SELECT balance FROM accounts WHERE account_name = 'Bob';  

-- IMPROVING CONCURRENCY BY USING锁  
-- Implementing row-level locking to prevent race conditions  
START TRANSACTION;  
    SELECT balance FROM accounts WHERE account_name = 'Alice' FOR UPDATE;  
    UPDATE accounts SET balance = balance - 100 WHERE account_name = 'Alice';  
    UPDATE accounts SET balance = balance + 100 WHERE account_name = 'Bob';  
COMMIT;  

-- Simulate another transaction with locking  
START TRANSACTION;  
    SELECT balance FROM accounts WHERE account_name = 'Alice' FOR UPDATE;  
    UPDATE accounts SET balance = balance - 50 WHERE account_name = 'Alice';  
    UPDATE accounts SET balance = balance + 50 WHERE account_name = 'Bob';  
COMMIT;  

-- Check the final balances  
SELECT * FROM accounts;  

-- BEST PRACTICES  
-- 1. Use transactions to wrap all related database operations  
-- 2. Use FOR UPDATE locks to ensure exclusive access to records  
-- 3. Keep transactions short to minimize lock contention  
-- 4. Test for possible deadlocks and include retry logic if necessary  

-- CLEAN UP TEST ENVIRONMENT  
-- Drop the sample table and database  
TRUNCATE TABLE accounts;  
DROP TABLE accounts;  
DROP DATABASE IF EXISTS race_condition_demo;  

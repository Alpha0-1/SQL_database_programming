-- Filename: 10-acid_properties.sql
-- Topic: ACID Properties in SQL Transactions
-- Description: Demonstrates Atomicity, Consistency, Isolation, and Durability

-- SET UP TEST ENVIRONMENT
-- Create a test database for ACID examples
CREATE DATABASE IF NOT EXISTS acid_demo;
USE acid_demo;

-- Create tables to demonstrate ACID properties
CREATE TABLE IF NOT EXISTS transactions (
    transaction_id INT AUTO_INCREMENT PRIMARY KEY,
    transaction_type VARCHAR(20),
    amount DECIMAL(10,2),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS accounts (
    account_id INT AUTO_INCREMENT PRIMARY KEY,
    account_name VARCHAR(50),
    balance DECIMAL(10,2)
);

-- Insert sample data
INSERT INTO accounts (account_name, balance)
VALUES ('Alice', 1000.00),
       ('Bob', 500.00);

-- Load the InnoDB storage engine for ACID compliance
SHOW Engines;
SET GLOBAL DEFAULT_STORAGE_ENGINE = 'InnoDB';

-- ACID PROPERTY 1: ATOMICITY
-- Atomicity ensures that a transaction is all or nothing.
-- If any part of the transaction fails, the entire transaction is rolled back.

START TRANSACTION;
    INSERT INTO transactions (transaction_type, amount)
    VALUES ('Transfer', 500.00);
    
    UPDATE accounts SET balance = balance - 500.00 WHERE account_name = 'Alice';
    -- Simulate an error (e.g., insufficient funds)
    -- This will cause the transaction to roll back
COMMIT;

-- Check if the transaction was successful
SELECT * FROM accounts WHERE account_name = 'Alice';
SELECT * FROM transactions;

-- ACID PROPERTY 2: CONSISTENCY
-- Consistency ensures that the database remains in a valid state throughout the transaction.

START TRANSACTION;
    SELECT balance FROM accounts WHERE account_name = 'Alice';
    UPDATE accounts SET balance = balance - 2000.00 WHERE account_name = 'Alice';
    -- Check if the balance remains positive after the update
    -- If not, the transaction should be rolled back
COMMIT;

-- Verify the consistency of the data
SELECT * FROM accounts WHERE account_name = 'Alice';

-- ACID PROPERTY 3: ISOLATION
-- Isolation ensures that multiple transactions can occur concurrently without interfering with each other.

-- Simulate concurrent transactions
START TRANSACTION;
    SELECT balance FROM accounts WHERE account_name = 'Alice' FOR UPDATE;
    UPDATE accounts SET balance = balance + 100.00 WHERE account_name = 'Alice';
    -- This transaction will block other transactions from modifying 'Alice's account
COMMIT;

-- Another session attempting to modify 'Alice's account
START TRANSACTION;
    SELECT balance FROM accounts WHERE account_name = 'Alice' FOR UPDATE;
    UPDATE accounts SET balance = balance - 50.00 WHERE account_name = 'Alice';
COMMIT;

-- Check the final balance
SELECT balance FROM accounts WHERE account_name = 'Alice';

-- ACID PROPERTY 4: DURABILITY
-- Durability ensures that committed transactions remain permanent even after system failures.

START TRANSACTION;
    INSERT INTO transactions (transaction_type, amount)
    VALUES ('Deposit', 200.00);
    
    UPDATE accounts SET balance = balance + 200.00 WHERE account_name = 'Bob';
COMMIT;

-- Simulate a system crash (e.g., restart the database)
-- After restarting, check if the transaction is still present
SELECT * FROM transactions;
SELECT * FROM accounts WHERE account_name = 'Bob';

-- CLEAN UP TEST ENVIRONMENT
-- Drop the sample tables and database
TRUNCATE TABLE transactions;
TRUNCATE TABLE accounts;
DROP TABLE transactions;
DROP TABLE accounts;
DROP DATABASE IF EXISTS acid_demo;



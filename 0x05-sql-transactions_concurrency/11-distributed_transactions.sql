-- Filename: 11-distributed_transactions.sql
-- Topic: Distributed Transactions
-- Description: Demonstrating transactions across multiple databases

-- SET UP TEST ENVIRONMENT
-- Create a global test database and two sample databases
CREATE DATABASE IF NOT EXISTS distributed_transaction_demo;
USE distributed_transaction_demo;

-- Create a table to track the two-phase commit process
CREATE TABLE IF NOT EXISTS transaction_coordinates (
    tx_id INT AUTO_INCREMENT PRIMARY KEY,
    database_name VARCHAR(50),
    status ENUM('Prepare', 'Commit', 'Rollback'),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create sample databases and tables
CREATE DATABASE IF NOT EXISTS db1;
USE db1;
CREATE TABLE IF NOT EXISTS customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_name VARCHAR(50),
    account_balance DECIMAL(10,2)
);
INSERT INTO customers (customer_name, account_balance)
VALUES ('Alice', 1000.00);

CREATE DATABASE IF NOT EXISTS db2;
USE db2;
CREATE TABLE IF NOT EXISTS orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT,
    order_amount DECIMAL(10,2),
    FOREIGN KEY (customer_id) REFERENCES db1.customers(customer_id)
);

-- Simulate a distributed transaction using two-phase commit

-- 1. Prepare Phase: Coordinate between databases
START TRANSACTION;
    -- Update customer's balance in db1
    USE db1;
    UPDATE customers SET account_balance = account_balance - 500 WHERE customer_name = 'Alice';
    
    -- Record the preparation in the coordinate table
    USE distributed_transaction_demo;
    INSERT INTO transaction_coordinates (database_name, status) VALUES ('db1', 'Prepare');
    
    -- Simulate a commitment to the transaction
    -- (Assume db2 is prepared to commit as well)
    INSERT INTO transaction_coordinates (database_name, status) VALUES ('db2', 'Prepare');
COMMIT;

-- 2. Commit Phase: Finalize the transaction in all databases
START TRANSACTION;
    -- Commit changes in db1
    USE db1;
    -- Since it's a distributed transaction, the commit is coordinated
    -- (Assume the commit is initiated based on the prepare phase)
    
    -- Record the commit in the coordinate table
    USE distributed_transaction_demo;
    UPDATE transaction_coordinates
    SET status = 'Commit'
    WHERE tx_id = 1;  -- Assuming tx_id 1 was the prepared transaction
    
    -- Simulate committing changes in db2
    USE db2;
    INSERT INTO orders (customer_id, order_amount)
    VALUES (1, 500.00);  -- Assuming customer_id 1 exists in db1
    
    -- Final commit
COMMIT;

-- Verify the transaction outcome
USE db1;
SELECT * FROM customers WHERE customer_name = 'Alice';

USE db2;
SELECT * FROM orders WHERE customer_id = 1;

-- Handle potential rollbacks
START TRANSACTION;
    -- Attempt an update that might fail
    USE db1;
    UPDATE customers SET account_balance = account_balance - 600 WHERE customer_name = 'Alice';
    
    -- If an error occurs, rollback the transaction
    -- Simulate an error condition and rollback the transaction
ROLLBACK;

-- Verify the rollback
USE db1;
SELECT * FROM customers WHERE customer_name = 'Alice';

-- BEST PRACTICES
-- 1. Use a reliable two-phase commit protocol for distributed transactions
-- 2. Monitor and log each phase of the transaction for debugging
-- 3. Implement proper error handling and rollback strategies
-- 4. Ensure network stability between connected databases
-- 5. Regularly test the transaction flow in a distributed environment

-- CLEAN UP TEST ENVIRONMENT
-- Drop the sample tables and databases
USE distributed_transaction_demo;
TRUNCATE TABLE transaction_coordinates;

USE db1;
TRUNCATE TABLE customers;
DROP TABLE customers;

USE db2;
TRUNCATE TABLE orders;
DROP TABLE orders;

DROP DATABASE IF EXISTS db1;
DROP DATABASE IF EXISTS db2;
DROP DATABASE IF EXISTS distributed_transaction_demo;

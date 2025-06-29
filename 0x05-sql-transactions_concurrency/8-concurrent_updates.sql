-- Filename: 8-concurrent_updates.sql
-- Topic: Handling Concurrent Updates with Transactions
-- Description: Examples of using transactions to manage simultaneous database updates

-- SET UP TEST ENVIRONMENT
-- We'll use a simple table to demonstrate concurrent updates
CREATE DATABASE IF NOT EXISTS concurrency_demo;
USE concurrency_demo;

-- Create a sample table to track inventory
CREATE TABLE IF NOT EXISTS products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_name VARCHAR(50),
    stock INT
);

-- Insert sample data
INSERT INTO products (product_name, stock)
VALUES ('Laptop', 10),
       ('Phone', 15),
       ('Tablet', 20);

-- START DEMONSTRATION
-- Scenario: Two users trying to update stock simultaneously
-- Without proper transaction handling, race conditions can occur

-- Simulate concurrent transactions (Imagine two concurrent sessions)

-- Session 1: Transaction A
START TRANSACTION;
    UPDATE products SET stock = stock - 1 WHERE product_name = 'Laptop';
    -- Imagine a delay here where another session starts
    -- Additional business logic
    -- (Pause to simulate concurrent access)
COMMIT;

-- Session 2: Transaction B
START TRANSACTION;
    UPDATE products SET stock = stock - 1 WHERE product_name = 'Laptop';
    -- Additional business logic
COMMIT;

-- Check the final state
SELECT * FROM products;

-- Discussion: What if both transactions tried to update the same row?
-- Without proper isolation levels or locking, the stock might be reduced by 0 instead of 2
-- Let's see the result
SELECT stock FROM products WHERE product_name = 'Laptop';

-- IMPROVING CONCURRENCY WITH锁
-- Using explicit locking to prevent race conditions
START TRANSACTION;
    SELECT stock FROM products WHERE product_name = 'Laptop' FOR UPDATE;
    -- This locks the row for other transactions
    UPDATE products SET stock = stock - 1 WHERE product_name = 'Laptop';
COMMIT;

-- Simulate another attempt
START TRANSACTION;
    SELECT stock FROM products WHERE product_name = 'Laptop'; -- This will wait until the lock is released
    UPDATE products SET stock = stock - 1 WHERE product_name = 'Laptop';
COMMIT;

-- Check the final stock
SELECT stock FROM products WHERE product_name = 'Laptop';

-- BEST PRACTICES
-- 1. Use transactions to wrap all related database operations
-- 2. Choose the appropriate isolation level for your application needs
-- 3. Use locks selectively to prevent contention while maintaining performance
-- 4. Handle potential deadlocks gracefully

-- CLEAN UP TEST ENVIRONMENT
-- Drop the sample table and database
TRUNCATE TABLE products;
DROP TABLE products;
DROP DATABASE IF EXISTS concurrency_demo;



-- 6-optimistic_locking.sql
-- This script demonstrates optimistic locking in SQL to manage concurrency.

-- Step 1: Creating the Test Database Table
-- Create a table to demonstrate optimistic locking with a version column.

-- Create the 'orders' table with an order_id, customer_name, order_total, and version column.
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_name VARCHAR(100),
    order_total DECIMAL(10,2),
    version INT DEFAULT 1
);

-- Step 2: Inserting Sample Data
-- Insert sample records into the orders table.

INSERT INTO orders (order_id, customer_name, order_total, version)
VALUES (1, 'Alice', 100.00, 1);

INSERT INTO orders (order_id, customer_name, order_total, version)
VALUES (2, 'Bob', 200.00, 1);

-- Step 3: Without Optimistic Locking: Demonstrating Potential Conflict
-- Show how without optimistic locking, concurrent updates can cause data inconsistency.

-- Transaction 1: Read and update order 1 without version check.
START TRANSACTION;
SELECT * FROM orders WHERE order_id = 1;
-- Simulate some processing or delay.
UPDATE orders SET order_total = 110.00 WHERE order_id = 1;
-- Commit the transaction.
COMMIT;

-- Transaction 2: Read and update order 1 without version check.
START TRANSACTION;
SELECT * FROM orders WHERE order_id = 1;
-- Simulate some processing or delay.
UPDATE orders SET order_total = 120.00 WHERE order_id = 1;
-- Commit the transaction.
COMMIT;

-- Check the result: The order_total might be incorrect as both transactions modified the same record without knowing about each other.
SELECT * FROM orders WHERE order_id = 1;

-- Step 4: Implementing Optimistic Locking
-- Use a version column to detect concurrent modifications.

-- Transaction A: Read and update order 1 with version check.
START TRANSACTION;
SELECT * FROM orders WHERE order_id = 1 FOR UPDATE;

-- Update the order_total and increment the version number.
UPDATE orders SET order_total = 110.00, version = version + 1 WHERE order_id = 1;
COMMIT;

-- Transaction B: Read and update order 1 with version check.
START TRANSACTION;
SELECT * FROM orders WHERE order_id = 1 FOR UPDATE;

-- Check if the version has been updated.
SELECT version FROM orders WHERE order_id = 1;

-- If the version matches, proceed with the update.
-- Here, we'll assume the version has been incremented by Transaction A, leading to a conflict.
UPDATE orders SET order_total = 120.00 WHERE order_id = 1 AND version = 1;

-- This should fail because the version in the WHERE clause does not match the current version in the database.
COMMIT;

-- Check the result: Only one transaction should successfully update the order_total.
SELECT * FROM orders WHERE order_id = 1;

-- Step 5: Handling Conflicts
-- Catching and handling optimistic locking conflicts.

-- Rollback the transaction in case of conflict.
START TRANSACTION;
SELECT * FROM orders WHERE order_id = 1 FOR UPDATE;

-- Attempt to update the order_total with an outdated version.
UPDATE orders SET order_total = 130.00 WHERE order_id = 1 AND version = 1;

-- If the update fails due to a version mismatch, rollback.
IF @@ROWCOUNT = 0
BEGIN
    ROLLBACK;
    RAISERROR('Conflict detected: Another transaction has modified this row.', 16, 1);
END
ELSE
BEGIN
    UPDATE orders SET version = version + 1 WHERE order_id = 1;
    COMMIT;
END

-- Step 6: Best Practices for Optimistic Locking
-- - Always include a version column in tables requiring optimistic concurrency control.
-- - Use FOR UPDATE clause to enforce read locking during transactions.
-- - Handle version mismatches gracefully by rolling back transactions and re-reading the data if necessary.
-- - Monitor for frequent conflicts that may indicate contention and consider adjusting the concurrency model or optimizing transactions.

-- Step 7: Cleanup
-- Drop the test table after use.

DROP TABLE orders;

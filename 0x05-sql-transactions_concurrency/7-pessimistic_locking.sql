-- 7-pessimistic_locking.sql
-- This script demonstrates pessimistic locking in SQL to manage concurrency.

-- Step 1: Understanding Pessimistic Locking
-- Pessimistic locking assumes that conflicts are likely and locks data upon access to prevent concurrent modifications.

-- Step 2: Creating Test Data
-- Create a simple table to simulate inventory management.

CREATE TABLE inventory (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    stock INT
);

-- Insert sample data
INSERT INTO inventory VALUES (1, 'Laptop', 10);
INSERT INTO inventory VALUES (2, 'Smartphone', 20);

-- Step 3: Demonstrating Pessimistic Locking

-- Transaction 1: Locking and updating inventory
START TRANSACTION;
-- Lock the product with ID 1 to prevent concurrent access
SELECT * FROM inventory WHERE product_id = 1 FOR UPDATE;
-- Simulate processing time, e.g., checking stock availability
WAITFOR DELAY '00:00:10'; -- Replace with appropriate delay mechanism if necessary
-- Update the stock level
UPDATE inventory SET stock = 9 WHERE product_id = 1;
COMMIT;

-- Transaction 2: Attempting to access locked product
START TRANSACTION;
-- This will wait until the lock is released from product_id 1
SELECT * FROM inventory WHERE product_id = 1 FOR UPDATE;
-- Update being blocked
UPDATE inventory SET stock = 15 WHERE product_id = 1;
COMMIT;

-- Step 4: Handling Locking Contentions and Deadlocks
-- Example of detecting and handling deadlocks
SET lock_timeout = '5s'; -- Set lock timeout to 5 seconds

START TRANSACTION;
SELECT * FROM inventory WHERE product_id = 2 FOR UPDATE;
-- Simulate processing time
WAITFOR DELAY '00:00:10';
COMMIT;

-- Step 5: Best Practices for Pessimistic Locking
-- - Keep transactions short to minimize lock duration
-- - Use the least restrictive locking necessary (e.g., row-level instead of table-level)
-- - Close transactions as soon as possible after committing or rolling back
-- - Implement proper isolation levels to prevent unnecessary locks

-- Step 6: Cleanup
-- Drop the test table after use
DROP TABLE inventory;

-- Step 7: Notes for Learners
-- - Pessimistic locking is useful in scenarios with high update contention
-- - It prevents conflicts but can lead to increased contention and potential deadlocks
-- - Always test pessimistic locking scenarios to understand their impact on performance
-- - Consider using optimistic locking in environments with low update contention
-- - Use database-specific features and best practices when implementing locks

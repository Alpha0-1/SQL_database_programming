-- 5-locking_mechanisms.sql
-- This script demonstrates explicit locking mechanisms in SQL

-- Step 1: What is Explicit Locking?
-- Explicit locking allows developers to manually control locks on database objects
-- This can help in preventing race conditions and ensuring data consistency

-- Step 2: Understanding Lock Types
-- Common lock types:
-- 1. Shared Lock (S): Allows concurrent reads but blocks writes
-- 2. Exclusive Lock (X): Blocks all other locks (read and write)
-- 3. Update Lock (U): Prevents other transactions from reading or modifying a row while it is being updated

-- Step 3: Creating Test Data
-- Create a simple table to demonstrate locking mechanisms

-- Create a sample table
CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    price DECIMAL(10,2),
    stock INT
);

-- Insert sample data
INSERT INTO products VALUES (1, 'Laptop', 999.99, 10);
INSERT INTO products VALUES (2, 'Smartphone', 699.99, 20);

-- Step 4: Demonstrating Locking Mechanisms

-- Example 1: Read Lock (Shared Lock)
START TRANSACTION;
-- Acquire a read lock on the first product
SELECT * FROM products WHERE product_id = 1 FOR SHARE;
-- Simulate concurrent read access
-- No conflict, as read locks are compatible
COMMIT;

-- Example 2: Write Lock (Exclusive Lock)
START TRANSACTION;
-- Acquire a write lock on the first product
SELECT * FROM products WHERE product_id = 1 FOR UPDATE;
-- This prevents other transactions from modifying or reading the locked row
-- Attempting to read or modify this row in another transaction will block
COMMIT;

-- Example 3: Table-Level Lock
START TRANSACTION;
-- Lock the entire products table for exclusive access
LOCK TABLE products IN EXCLUSIVE MODE;
-- No other transaction can read or write to this table until the lock is released
COMMIT;

-- Example 4: Using Locks in Transactions
START TRANSACTION;
-- Lock and update product 1
SELECT * FROM products WHERE product_id = 1 FOR UPDATE;
UPDATE products SET stock = 9 WHERE product_id = 1;
COMMIT;

-- Step 5: Handling Lock Contention
-- If a transaction cannot acquire a lock, it will wait until the lock is released
-- To prevent deadlocks, keep transactions short and acquire locks in a consistent order

-- Example: Handling Lock Timeouts (PostgreSQL-specific)
-- Set a lock timeout (e.g., 1 second)
SET lock_timeout = '1s';

-- Try to acquire a lock, but it will timeout after 1 second if it cannot
SELECT * FROM products WHERE product_id = 1 FOR UPDATE NOWAIT;

-- Step 6: Best Practices for Locking
-- 1. Use row-level locking instead of table-level locking whenever possible
-- 2. Keep transactions short to minimize lock duration
-- 3. Use appropriate isolation levels to reduce locking overhead
-- 4. Always test for locking behavior in a controlled environment

-- Step 7: Cleanup Test Data
-- Drop the sample table
DROP TABLE products;

-- Step 8: Notes
-- - Explicit locking is a powerful tool but must be used carefully
-- - Overuse of locks can lead to performance issues and deadlocks
-- - Always prioritize database-engine-managed locking over manual locking
-- - Use locking mechanisms only when necessary and in conjunction with proper transaction management

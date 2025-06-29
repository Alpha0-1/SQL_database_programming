/*
 * Title: Multi-column Indexes
 * Description: Demonstrates how to create and use composite indexes
 * 
 * Composite indexes (multi-column indexes) can:
 * - Optimize queries with multiple conditions
 * - Improve sorting performance
 * - Reduce the number of indexes you need
 */

-- Step 1: Create a sample table
CREATE TABLE transactions (
    transaction_id INT PRIMARY KEY,
    user_id INT,
    product_id INT,
    transaction_date DATE
);

-- Step 2: Populate sample data
INSERT INTO transactions VALUES
    (1, 1, 101, '2023-01-01'),
    (2, 2, 102, '2023-01-02'),
    (3, 3, 103, '2023-01-03');

-- Step 3: Create a composite index on user_id and transaction_date
CREATE INDEX idx_user_transaction ON transactions(user_id, transaction_date);

-- Step 4: Query that benefits from the composite index
SELECT * FROM transactions 
WHERE user_id = 1 AND transaction_date >= '2023-01-01';

-- Step 5: Verify the index usage (PostgreSQL-specific)
EXPLAIN SELECT * FROM transactions 
WHERE user_id = 1 AND transaction_date >= '2023-01-01';

/*
 * Explanation:
 * - Composite indexes are ordered by the columns specified
 * - Leading columns in the index are most important for query optimization
 * - Use multi-column indexes for queries with multiple conditions
 */

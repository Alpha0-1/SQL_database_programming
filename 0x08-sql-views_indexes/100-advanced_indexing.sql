/*
 * Title: Advanced Indexing Strategies
 * Description: Demonstrates advanced indexing techniques to optimize complex SQL queries
 * 
 * Advanced indexing strategies include:
 * - Clustered indexes
 * - Bitmap indexes
 * - Function-based composite indexes
 */

-- Step 1: Create a sample table
CREATE TABLE transactions (
    transaction_id INT PRIMARY KEY,
    user_id INT,
    product_id INT,
    transaction_date DATE,
    transaction_amount DECIMAL(10,2)
);

-- Step 2: Populate sample data
INSERT INTO transactions VALUES
    (1, 1, 101, '2023-01-01', 100.00),
    (2, 2, 102, '2023-01-02', 200.00),
    (3, 3, 103, '2023-01-03', 150.00),
    (4, 1, 104, '2023-01-04', 300.00),
    (5, 2, 105, '2023-01-05', 250.00);

-- Step 3: Create a clustered index on a frequently accessed column
CREATE CLUSTERED INDEX idx_transaction_date ON transactions(transaction_date);

-- Step 4: Create a bitmap index for columns with repeating values
CREATE INDEX idx_product_transaction_amount 
ON transactions(product_id) 
WHERE transaction_amount < 200.00;

-- Step 5: Create a composite function-based index
CREATE INDEX idx_user_monthly_transactions
ON transactions(user_id, (EXTRACT(MONTH FROM transaction_date)));

-- Step 6: Demonstrate the use of advanced indexes in a query
SELECT user_id, transaction_date, transaction_amount
FROM transactions
WHERE user_id = 1 AND transaction_date >= '2023-01-01' AND transaction_amount < 200.00;

-- Step 7: Verify the index usage (PostgreSQL-specific)
EXPLAIN SELECT user_id, transaction_date, transaction_amount
FROM transactions
WHERE user_id = 1 AND transaction_date >= '2023-01-01' AND transaction_amount < 200.00;

/*
 * Explanation:
 * - Clustered indexes organize data to improve query performance
 * - Bitmap indexes are efficient for columns with low cardinality
 * - Composite function-based indexes optimize specific query patterns
 */

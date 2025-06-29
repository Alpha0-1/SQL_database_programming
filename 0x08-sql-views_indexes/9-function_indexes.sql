/*
 * Title: Function-Based Indexes
 * Description: Demonstrates how to create and use function-based indexes
 * 
 * Function-based indexes allow you to:
 * - Index the result of a function applied to a column
 * - Optimize queries that use functions in WHERE, ORDER BY, or GROUP BY clauses
 * - Use functions like LOWER, LEFT, or EXTRACT
 */

-- Step 1: Create a sample table
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    full_name VARCHAR(100),
    email VARCHAR(100),
    birth_date DATE
);

-- Step 2: Populate sample data
INSERT INTO customers VALUES
    (1, 'John Doe', 'john.doe@example.com', '1990-05-15'),
    (2, 'Jane Smith', 'jane.smith@example.com', '1985-08-20'),
    (3, 'Bob Johnson', 'bob.johnson@example.com', '1992-01-10');

-- Step 3: Create a function-based index on the extracted year from birth_date
CREATE INDEX idx_birth_year ON customers(EXTRACT(YEAR FROM birth_date));

-- Step 4: Query that benefits from the function-based index
SELECT full_name, EXTRACT(YEAR FROM birth_date) AS birth_year 
FROM customers 
WHERE EXTRACT(YEAR FROM birth_date) >= 1990;

-- Step 5: Verify the index usage (PostgreSQL-specific)
EXPLAIN SELECT full_name, EXTRACT(YEAR FROM birth_date) AS birth_year 
FROM customers 
WHERE EXTRACT(YEAR FROM birth_date) >= 1990;

/*
 * Explanation:
 * - Function-based indexes can optimize queries with functions on columns
 * - Use functions that are consistently applied in WHERE or ORDER BY clauses
 * - Be cautious of the overhead of maintaining function-based indexes
 */

/*
 * Title: Basic Index Creation
 * Description: Demonstrates how to create and use basic indexes in SQL
 * 
 * Indexes improve query performance by:
 * - Allowing faster access to rows
 * - Reducing disk I/O
 * - Speeding up WHERE, ORDER BY, and JOIN operations
 */

-- Step 1: Create a sample table
CREATE TABLE sales (
    sale_id INT PRIMARY KEY,
    product_id INT,
    quantity INT,
    sale_date DATE
);

-- Step 2: Populate sample data
INSERT INTO sales VALUES
    (1, 101, 10, '2023-01-01'),
    (2, 102, 20, '2023-01-02'),
    (3, 103, 30, '2023-01-03');

-- Step 3: Create a basic index on the product_id column
CREATE INDEX idx_product_id ON sales(product_id);

-- Step 4: Query that benefits from the index
SELECT * FROM sales WHERE product_id = 101;

-- Step 5: Verify the index usage (PostgreSQL-specific)
EXPLAIN SELECT * FROM sales WHERE product_id = 101;

/*
 * Explanation:
 * - Indexes are created on columns that are frequently queried
 * - Use `EXPLAIN` to verify if indexes are being used
 * - Be cautious of index bloat and over-indexing
 */

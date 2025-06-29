/*
 * Title: Index Optimization
 * Description: Demonstrates how to optimize queries with multiple indexes
 * 
 * Index optimization involves:
 * - Balancing between query speed and index maintenance
 * - Using covering indexes
 * - Avoiding over-indexing
 */

-- Step 1: Create a sample table
CREATE TABLE sales (
    sale_id INT PRIMARY KEY,
    product_id INT,
    quantity INT,
    sale_date DATE,
    customer_id INT
);

-- Step 2: Populate sample data
INSERT INTO sales VALUES
    (1, 101, 10, '2023-01-01', 1),
    (2, 102, 20, '2023-01-02', 2),
    (3, 103, 30, '2023-01-03', 3);

-- Step 3: Create indexes for optimization
CREATE INDEX idx_product ON sales(product_id);
CREATE INDEX idx_customer ON sales(customer_id, sale_date);

-- Step 4: Query that benefits from both indexes
SELECT product_id, quantity, sale_date, customer_id 
FROM sales 
WHERE product_id = 101 AND sale_date >= '2023-01-01';

-- Step 5: Verify index usage (PostgreSQL-specific)
EXPLAIN SELECT product_id, quantity, sale_date, customer_id 
FROM sales 
WHERE product_id = 101 AND sale_date >= '2023-01-01';

/*
 * Explanation:
 * - Multiple indexes can work together to optimize complex queries
 * - Use indexes on frequently queried columns
 * - Be cautious of overlapping indexes
 */

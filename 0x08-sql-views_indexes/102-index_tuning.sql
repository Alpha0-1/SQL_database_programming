/*
 * Title: Index Tuning
 * Description: Demonstrates techniques for optimizing and maintaining indexes
 * 
 * Index tuning includes:
 * - Optimizing existing indexes
 * - Adding new indexes for better performance
 * - Dropping unused indexes
 */

-- Step 1: Create a sample table
CREATE TABLE sales (
    sale_id INT PRIMARY KEY,
    product_id INT,
    quantity INT,
    sale_date DATE,
    sale_location VARCHAR(50)
);

-- Step 2: Create existing indexes
CREATE INDEX idx_product ON sales(product_id);
CREATE INDEX idx_sale_date ON sales(sale_date);

-- Step 3: Populate sample data
INSERT INTO sales VALUES
    (1, 101, 10, '2023-01-01', 'New York'),
    (2, 102, 20, '2023-01-02', 'London'),
    (3, 103, 30, '2023-01-03', 'Paris'),
    (4, 104, 25, '2023-01-04', 'Tokyo'),
    (5, 105, 15, '2023-01-05', 'Sydney');

-- Step 4: Optimize an existing index by adding a new column
CREATE INDEX idx_product_quantity ON sales(product_id, quantity);

-- Step 5: Add a covering index for a frequently used query
CREATE INDEX idx_location_date ON sales(sale_location, sale_date);

-- Step 6: Drop an unused index
DROP INDEX idx_sale_date;

-- Step 7: Query that benefits from the new indexes
SELECT product_id, quantity, sale_location 
FROM sales
WHERE sale_location = 'New York' AND sale_date >= '2023-01-01';

-- Step 8: Verify the index usage (PostgreSQL-specific)
EXPLAIN SELECT product_id, quantity, sale_location 
FROM sales
WHERE sale_location = 'New York' AND sale_date >= '2023-01-01';

/*
 * Explanation:
 * - Optimize indexes by adding frequently used columns
 * - Use covering indexes to reduce I/O operations
 * - Regularly review and remove unused indexes
 */

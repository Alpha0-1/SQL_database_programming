/*
 * Title: Index Maintenance
 * Description: Demonstrates how to maintain and monitor indexes
 * 
 * Index maintenance includes:
 * - Monitoring index usage
 * - Rebuilding indexes
 * - Cleaning up unused indexes
 */

-- Step 1: Create a sample table
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    product_id INT,
    quantity INT,
    order_date DATE
);

-- Step 2: Create an index
CREATE INDEX idx_order_date ON orders(order_date);

-- Step 3: Insert sample data
INSERT INTO orders VALUES
    (1, 101, 10, '2023-01-01'),
    (2, 102, 20, '2023-01-02'),
    (3, 103, 30, '2023-01-03');

-- Step 4: Analyze index usage (PostgreSQL-specific)
SELECT 
    relname AS index_name,
    pg_size_pretty(index_size) AS index_size,
    idx_scan AS index_scans
FROM 
    pg_stat_all_indexes 
WHERE 
    indexrelname = 'idx_order_date';

-- Step 5: Rebuild the index to optimize performance
REINDEX INDEX idx_order_date;

-- Step 6: Drop the index if it's no longer needed
DROP INDEX idx_order_date;

/*
 * Explanation:
 * - Regularly monitor index usage to ensure they're beneficial
 * - Rebuild indexes when they become fragmented
 * - Drop unused or redundant indexes to save resources
 */

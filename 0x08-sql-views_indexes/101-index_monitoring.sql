/*
 * Title: Index Usage Monitoring
 * Description: Demonstrates how to monitor and analyze index usage
 * 
 * Effective index monitoring involves:
 * - Tracking index usage statistics
 * - Identifying unused or redundant indexes
 * - Analyzing query execution plans
 */

-- Step 1: Create a sample table
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    product_id INT,
    customer_id INT,
    order_date DATE,
    order_status VARCHAR(20)
);

-- Step 2: Create an index
CREATE INDEX idx_order_status_date ON orders(order_status, order_date);

-- Step 3: Populate sample data
INSERT INTO orders VALUES
    (1, 101, 1, '2023-01-01', 'Completed'),
    (2, 102, 2, '2023-01-02', 'Pending'),
    (3, 103, 3, '2023-01-03', 'Completed'),
    (4, 104, 1, '2023-01-04', 'Shipped'),
    (5, 105, 2, '2023-01-05', 'Canceled');

-- Step 4: Monitor index usage statistics
SELECT 
    relname AS index_name,
    idx_scan AS total_scans,
    idx_tup_read AS rows_read,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM 
    pg_stat_all_indexes
WHERE 
    indexrelname = 'idx_order_status_date';

-- Step 5: Query that benefits from the index
SELECT product_id, customer_id 
FROM orders
WHERE order_status = 'Completed' AND order_date >= '2023-01-01';

-- Step 6: Verify the index usage (PostgreSQL-specific)
EXPLAIN SELECT product_id, customer_id 
FROM orders
WHERE order_status = 'Completed' AND order_date >= '2023-01-01';

/*
 * Explanation:
 * - Use system views to monitor index usage and performance
 * - Regularly check for unused or redundant indexes
 * - Optimize and clean up indexes as needed
 */

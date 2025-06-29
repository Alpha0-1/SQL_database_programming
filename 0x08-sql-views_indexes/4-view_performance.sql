/*
 * Title: Views and Performance
 * Description: Demonstrates how views can impact performance and how to optimize them
 * 
 * Views can improve or degrade performance depending on their usage. This example shows:
 * - How to create an efficient view
 * - How to use indexes to optimize views
 * - How to avoid overusing views
 */

-- Step 1: Create a sample table with sample data
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    order_date DATE,
    total_amount DECIMAL(10,2)
);

-- Step 2: Populate sample data
INSERT INTO orders VALUES
    (1, 1, '2023-01-01', 100.00),
    (2, 2, '2023-01-02', 200.00),
    (3, 3, '2023-01-03', 150.00);

-- Step 3: Create a view without an index
CREATE VIEW recent_orders AS
SELECT *
FROM orders
WHERE order_date >= '2023-01-01';

-- Step 4: Show the execution plan
EXPLAIN SELECT * FROM recent_orders WHERE total_amount > 150.00;

-- Step 5: Create an index to optimize the view
CREATE INDEX idx_order_date ON orders(order_date);

-- Step 6: Show the optimized execution plan
EXPLAIN SELECT * FROM recent_orders WHERE total_amount > 150.00;

/*
 * Explanation:
 * - Views can benefit from underlying table indexes
 * - Use `EXPLAIN` to analyze query performance
 * - Always test views with your workload
 */

-- File: 4-join_optimization.sql
-- Topic: JOIN optimization
-- Description: Techniques for optimizing JOIN operations

/*
 * Join Optimization Examples
 *
 * This file demonstrates different techniques for optimizing JOIN operations
 */

-- Example 1: Choosing the right join order
SELECT * FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE c.customer_name = 'John Doe';

-- Example 2: Using indexes on join columns
CREATE INDEX idx_order_customer_id ON orders(customer_id);
CREATE INDEX idx_customer_id ON customers(customer_id);

-- Example 3: Avoiding unnecessary joins
-- Poor performing query with extra join
SELECT * FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN payments p ON o.order_id = p.order_id
WHERE c.customer_name = 'John Doe';

-- Optimized version
SELECT * FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE c.customer_name = 'John Doe';

-- Example 4: Using appropriate join types
-- INNER JOIN example
SELECT * FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id;

-- LEFT JOIN example
SELECT * FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id;

-- Example 5: Reducing data size before joining
SELECT c.customer_id, c.customer_name, o.order_total
FROM customers c
JOIN (
    SELECT customer_id, SUM(order_total) as total
    FROM orders
    GROUP BY customer_id
) o ON c.customer_id = o.customer_id;

-- Example 6: Using EXPLAIN to analyze join performance
EXPLAIN SELECT * FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE c.customer_name = 'John Doe';

-- Example 7: Hash vs Merge Join
-- For large tables, hash joins are often faster
EXPLAIN SELECT * FROM customers c
JOIN orders o ON c.customer_id = o.customer_id;

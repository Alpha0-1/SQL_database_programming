/*
 * Title: Partial/Filtered Indexes
 * Description: Demonstrates how to create and use partial indexes
 * 
 * Partial indexes (filtered indexes) can:
 * - Improve query performance by indexing only relevant rows
 * - Reduce index size
 * - Speed up queries with conditional filters
 */

-- Step 1: Create a sample table
CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    category VARCHAR(50),
    price DECIMAL(10,2)
);

-- Step 2: Populate sample data
INSERT INTO products VALUES
    (1, 'Laptop', 'Electronics', 1000.00),
    (2, 'Phone', 'Electronics', 800.00),
    (3, 'Shirt', 'Clothing', 30.00);

-- Step 3: Create a partial index on electronics products
CREATE INDEX idx_electronics_products 
ON products(price) 
WHERE category = 'Electronics';

-- Step 4: Query that benefits from the partial index
SELECT product_name, price 
FROM products 
WHERE category = 'Electronics' AND price < 900.00;

-- Step 5: Verify the index usage (PostgreSQL-specific)
EXPLAIN SELECT product_name, price 
FROM products 
WHERE category = 'Electronics' AND price < 900.00;

/*
 * Explanation:
 * - Partial indexes only index a subset of rows
 * - Use them for columns with specific filters or conditions
 * - Reduces index overhead while improving performance
 */

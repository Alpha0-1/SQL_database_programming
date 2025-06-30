-- 12-indexing_strategies.sql
-- Indexing Strategies for Data Warehouses

-- Step 1: Create Fact and Dimension Tables (for demonstration purposes)

CREATE TABLE fact_sales (
    sales_id INT,
    order_date DATE,
    customer_id INT,
    product_id INT,
    quantity INT,
    amount DECIMAL(10, 2)
);

CREATE TABLE dim_customer (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100),
    region VARCHAR(50)
);

CREATE TABLE dim_product (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    category VARCHAR(50)
);

-- Step 2: Bitmap Index Example
-- Useful for low-cardinality columns
CREATE BITMAP INDEX idx_category ON dim_product(category);

COMMENT ON INDEX idx_category IS 'Bitmap index on low-cardinality columns (category).';

-- Step 3: Partitioned Index Example
-- Partitioning helps in managing large tables
CREATE INDEX idx_order_date ON fact_sales(order_date) INTERVAL '1 month';

COMMENT ON INDEX idx_order_date IS 'Partitioned index on order_date to improve query performance on historical data.';

-- Step 4: Foreign Key Index Example
-- Improve performance of join operations
CREATE INDEX idx_customer_id ON fact_sales(customer_id);

COMMENT ON INDEX idx_customer_id IS 'Index on foreign key (customer_id) to optimize join operations with dim_customer.';

-- Step 5: Example of Using Indexes
-- Query that benefits from bitmap and partitioned indexes
SELECT p.product_name, c.region, SUM(f.amount) AS total Sales
FROM fact_sales f
JOIN dim_customer c ON f.customer_id = c.customer_id
JOIN dim_product p ON f.product_id = p.product_id
WHERE p.category = 'Electronics'
AND f.order_date BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY p.product_name, c.region;

-- Explanation and Best Practices:
/*
Key Indexing Strategies for Data Warehouses:

1. **Bitmap Indexes**:
    - Ideal for low-cardinality columns (e.g., category, region).
    - Significantly reduces storage and improves query performance for filters on these columns.

2. **Partitioned Indexes**:
    - Creates smaller, more manageable index partitions.
    - Useful for time-based columns (e.g., order_date) to improve query performance on specific date ranges.

3. **Index on Foreign Keys**:
    - Improves join performance between fact and dimension tables.
    - Especially useful for frequently joined columns.

4. **Considerations**:
    - Avoid over-indexing to prevent excessive storage and maintenance overhead.
    - Regularly monitor and rebuild indexes to maintain performance.
    - Use Oracle-specific features like `INTERVAL` in partitioned indexes for automatic range management.

Optimal use of indexes can drastically improve query performance in a data warehouse, especially for large-scale analytical queries.
*/

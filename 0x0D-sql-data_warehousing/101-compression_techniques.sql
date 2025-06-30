-- 101-compression_techniques.sql
-- Data Compression Techniques

-- Step 1: Create a Fact Table with Compression
CREATE TABLE fact_sales (
    sales_id INT,
    order_date DATE,
    customer_id INT,
    product_id INT,
    quantity INT,
    amount DECIMAL(10, 2)
)
COMPRESS FOR ANALYSIS IN PROGRESS;

COMMENT ON TABLE fact_sales IS 'Fact table with compression enabled for analytical workloads.';

-- Step 2: Enable列Compression on a Dimension Table
ALTER TABLE dim_product
MODIFY (
    column product_name COMPRESS,
    column category COMPRESS
);

COMMENT ON TABLE dim_product IS 'Dimension table with column compression enabled for specific columns.';

-- Step 3: Insert Sample Data
INSERT INTO fact_sales (sales_id, order_date, customer_id, product_id, quantity, amount) VALUES
(1, '2023-01-01', 1, 101, 2, 150.00),
(2, '2023-01-02', 2, 102, 3, 200.00),
(3, '2023-01-03', 3, 103, 1, 500.00);

INSERT INTO dim_product (product_id, product_name, category, price) VALUES
(101, 'Laptop', 'Electronics', 999.99),
(102, 'Smartphone', 'Electronics', 699.99),
(103, 'Tablet', 'Electronics', 399.99);

-- Step 4: Query Examples
-- Query Fact Table with Compression
SELECT *
FROM fact_sales
WHERE order_date BETWEEN '2023-01-01' AND '2023-12-31';

-- Query Dimension Table with Column Compression
SELECT product_name, category
FROM dim_product
WHERE category = 'Electronics';

-- Explanation and Best Practices:
/*
Key Compression Techniques:

1. **Row Compression**:
    - Reduces storage by compressing rows based on similar data patterns.
    - Use for tables with semi-structured or text-heavy data.

2. **Column Compression**:
    - Compresses individual columns to reduce storage and improve query performance.
    - Ideal for columns with high repetition or data patterns (e.g., categorical data).

3. **Compression Levels**:
    - `NO_COMPRESSION`: No compression (default).
    - `COMPRESS FOR OLTP`: Optimized for transactional workloads.
    - `COMPRESS FOR ANALYSIS`: Optimized for analytical workloads.

4. Best Practices:
    - Compress columns or tables based on their usage (OLTP vs. OLAP).
    - Regularly analyze table compression benefits using Oracle compression advisors.
    - Use compression for large tables with repetitive data.

Compression is a critical technique for reducing storage costs and improving query performance in data warehouses. Choose the right compression method based on your workload and data characteristics.
*/

-- 100-columnar_storage.sql
-- Columnar Storage Concepts

-- Step 1: Create a Fact Table Using Row-wise Storage
CREATE TABLE fact_sales (
    sales_id INT,
    order_date DATE,
    customer_id INT,
    product_id INT,
    quantity INT,
    amount DECIMAL(10, 2)
)
ORGANIZATION ROW;

COMMENT ON TABLE fact_sales IS 'Example of row-wise storage for transactional operations.';

-- Step 2: Create a Columnar Table for Analytics
CREATE COLUMN TABLE dim_product (
    product_id INT,
    product_name VARCHAR(100),
    category VARCHAR(50),
    price DECIMAL(10, 2)
)
ORGANIZATION COLUMN;

COMMENT ON TABLE dim_product IS 'Example of columnar storage for analytical operations.';

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
-- Row-wise table operations
SELECT * FROM fact_sales
WHERE customer_id = 1;

-- Columnar table operations
SELECT category, AVG(price) AS avg_price
FROM dim_product
GROUP BY category;

-- Explanation of Columnar Storage:
/*
Key Concepts of Columnar Storage:

1. **Row-wise Storage**:
    - Organizes data by rows, suitable for OLTP (Online Transaction Processing).
    - Efficient for inserting, updating, and deleting records.

2. **Columnar Storage**:
    - Organizes data by columns, suitable for OLAP (Online Analytical Processing).
    - Benefits:
        - Compresses data more effectively (especially for columns with similar data types).
        - Reduces I/O operations during analytical queries.
        - Improves query performance on large datasets with column-specific filters.

3. Use Cases:
    - Use row-wise storage for transactional tables (fact tables).
    - Use columnar storage for analytical tables (dimension tables or pre-aggregated tables).

4. Best Practices:
    - Choose the storage type based on the table's primary use case (transactions vs. analytics).
    - Columnar tables are ideal for reporting and analysis, while row-wise tables are better for raw data storage.

Columnar storage is a powerful tool for improving query performance in data warehouses, especially for large-scale analytical workloads.
*/

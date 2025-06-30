-- 102-performance_optimization.sql
-- Performance Optimization in Data Warehouses

-- Step 1: Create Fact and Dimension Tables
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

-- Step 2: Optimize Queries with Indexes
CREATE INDEX idx_order_date ON fact_sales(order_date);

COMMENT ON INDEX idx_order_date IS 'Index on order_date to optimize time-based queries.';

-- Step 3: Partition Fact Table
ALTER TABLE fact_sales
PARTITION BY RANGE(order_date) (
    PARTITION p2023 VALUES LESS THAN ('2024-01-01'),
    PARTITION p2024 VALUES LESS THAN ('2025-01-01'),
    PARTITION p_max VALUES LESS THAN (MAXVALUE)
);

COMMENT ON TABLE fact_sales IS 'Fact table partitioned by order_date for improved query performance.';

-- Step 4: Use Materialized Views
CREATE MATERIALIZED VIEW mv_sales_summary
AS
SELECT 
    EXTRACT(MONTH FROM order_date) AS month,
    region,
    COUNT(*) AS total_orders,
    SUM(amount) AS total_sales
FROM fact_sales f
JOIN dim_customer c ON f.customer_id = c.customer_id
GROUP BY EXTRACT(MONTH FROM order_date), region;

COMMENT ON MATERIALIZED VIEW mv_sales_summary IS 'Materialized view for pre-aggregated sales data.';

-- Step 5: Insert Sample Data
INSERT INTO fact_sales (sales_id, order_date, customer_id, product_id, quantity, amount) VALUES
(1, '2023-01-01', 1, 101, 2, 150.00),
(2, '2023-01-02', 2, 102, 3, 200.00),
(3, '2023-01-03', 3, 103, 1, 500.00);

-- Step 6: Query Examples
-- Optimized Query with Index and Partitioning
SELECT month, region, total_orders, total_sales
FROM mv_sales_summary
WHERE month = 1;

-- Explanation and Best Practices:
/*
Key Performance Optimization Techniques:

1. **Indexing**:
    - Create indexes on columns used in WHERE and JOIN clauses.
    - Use bitmap and partitioned indexes for analytical queries.

2. **Partitioning**:
    - Split large tables into smaller, more manageable partitions.
    - Use range partitioning for time-based columns (e.g., order_date).

3. **Materialized Views**:
    - Pre-aggregate data to reduce query execution time.
    - Useful for frequently run analytical reports.

4. **Query Tuning**:
    - Use EXPLAIN PLAN to identify bottlenecks in query execution.
    - Optimize join operations by ensuring proper indexing and partitioning.

5. **Best Practices**:
    - Regularly analyze table statistics to ensure optimal query plans.
    - Monitor partition growth and adjust partition boundaries as needed.
    - Use automatic segment creation where possible.

These techniques can significantly improve query performance and overall efficiency in a data warehouse environment.
*/


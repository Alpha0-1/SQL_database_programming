-- 11-partitioning_strategies.sql
-- This file demonstrates various partitioning strategies for data warehouses
-- including range, list, hash, and composite partitioning.
-- The examples use Oracle SQL syntax.

-- Table creation for demonstration purposes.

-- Clear existing tables if they exist
DROP TABLE IF EXISTS fact_order Cascade;
DROP TABLE IF EXISTS dim_customer Cascade;
DROP TABLE IF EXISTS dim_product Cascade;
DROP TABLE IF EXISTS dim_time Cascade;

-- Create dimension tables
CREATE TABLE dim_customer (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100),
    region_id INT,
    load_date DATE
)
PARTITION BY RANGE (load_date)
(
    PARTITION p2023 VALUES LESS THAN (TO_DATE('01-JAN-2024', 'DD-MON-YYYY')),
    PARTITION p2024 VALUES LESS THAN (TO_DATE('01-JAN-2025', 'DD-MON-YYYY')),
    PARTITION p2025 VALUES LESS THAN (TO_DATE('01-JAN-2026', 'DD-MON-YYYY')),
    PARTITION p_max VALUES LESS THAN (MAXVALUE)
);

COMMENT ON TABLE dim_customer IS 
'Example of Range Partitioning on a dimension table based on load_date. This is useful for time-based queries and data aging.';

-- Create fact tables
CREATE TABLE fact_order (
    order_id INT,
    customer_id INT,
    product_id INT,
    order_date DATE,
    quantity INT,
    amount DECIMAL(10,2),
    region_id INT
);

CREATE TABLE fact_order (
    order_id INT,
    customer_id INT,
    product_id INT,
    order_date DATE,
    quantity INT,
    amount DECIMAL(10,2),
    region_id INT
)
PARTITION BY RANGE (order_date)
(
    PARTITION p_q1 VALUES LESS THAN (TO_DATE('01-APR-2023', 'DD-MON-YYYY')),
    PARTITION p_q2 VALUES LESS THAN (TO_DATE('01-JUL-2023', 'DD-MON-YYYY')),
    PARTITION p_q3 VALUES LESS THAN (TO_DATE('01-OCT-2023', 'DD-MON-YYYY')),
    PARTITION p_q4 VALUES LESS THAN (TO_DATE('01-JAN-2024', 'DD-MON-YYYY'))
);

COMMENT ON TABLE fact_order IS 
'Example of Range Partitioning on a fact table based on order_date. Each partition represents a quarter.';

-- List Partitioning example
CREATE TABLE fact_sales (
    transaction_id INT,
    customer_id INT,
    product_id INT,
    transaction_date DATE,
    amount DECIMAL(10,2),
    region_id INT
)
PARTITION BY LIST (region_id)
(
    PARTITION p_north VALUES (1,2,3),
    PARTITION p_south VALUES (4,5,6),
    PARTITION p_east VALUES (7,8,9),
    PARTITION p_west VALUES (10,11,12)
);

COMMENT ON TABLE fact_sales IS 
'Example of List Partitioning on a fact table based on region_id. Each partition contains specific regions.';

-- Hash Partitioning example
CREATE TABLE fact_log (
    log_id INT,
    user_id INT,
    log_time TIMESTAMP,
    action VARCHAR(50),
    details VARCHAR(200)
)
PARTITION BY HASH (user_id)
PARTITIONS 16;

COMMENT ON TABLE fact_log IS 
'Example of Hash Partitioning on a fact table based on user_id. The data is distributed evenly across partitions for parallel processing.';

-- Composite Partitioning example (Range + List)
CREATE TABLE fact_transaction (
    transaction_id INT,
    customer_id INT,
    transaction_date DATE,
    amount DECIMAL(10,2),
    region_id INT
)
PARTITION BY RANGE (transaction_date) 
SUBPARTITION BY LIST (region_id)
SUBPARTITIONS (
    p_north VALUES (1,2,3),
    p_south VALUES (4,5,6),
    p_east VALUES (7,8,9),
    p_west VALUES (10,11,12)
)
(
    PARTITION p_2023q1 VALUES LESS THAN (TO_DATE('01-APR-2023', 'DD-MON-YYYY')),
    PARTITION p_2023q2 VALUES LESS THAN (TO_DATE('01-JUL-2023', 'DD-MON-YYYY')),
    PARTITION p_2023q3 VALUES LESS THAN (TO_DATE('01-OCT-2023', 'DD-MON-YYYY')),
    PARTITION p_2023q4 VALUES LESS THAN (TO_DATE('01-JAN-2024', 'DD-MON-YYYY'))
);

COMMENT ON TABLE fact_transaction IS 
'Example of Composite Partitioning (Range + List) on a fact table. Partitions are first divided by date range, and then sub-partitioned by region_id.';

-- Usage Scenarios and Recommendations

-- 1. Range Partitioning:
-- Use when data can be naturally ordered (e.g., dates, transaction times).
-- Example: Partition fact_order by order_date quarterly.

-- 2. List Partitioning:
-- Use for grouping related data together (e.g., region, product categories).
-- Example: Partition fact_sales by region.

-- 3. Hash Partitioning:
-- Use when you need even distribution of data for parallel processing.
-- Example: Partition fact_log by user_id for load balancing.

-- 4. Composite Partitioning:
-- Use when you need multi-dimensional partitioning (e.g., date and region).
-- Example: Partition fact_transaction by date range and region.

-- Best Practices:
-- - Choose partition key based on query patterns.
-- - Avoid too many partitions to prevent management overhead.
-- - Monitor partition performance and adjust as needed.
-- - Use automatic segment creation where possible.
-- - Partition at the fact table level, not in dimensions.

-- Insert sample data (for demonstration purposes)

-- Sample data insertion for dim_customer
INSERT INTO dim_customer (customer_id, customer_name, region_id, load_date) VALUES
(1, 'Customer A', 1, '01-JAN-2023'),
(2, 'Customer B', 2, '01-MAR-2023'),
(3, 'Customer C', 3, '01-JUN-2023');

-- Sample data insertion for fact_order
INSERT INTO fact_order (order_id, customer_id, product_id, order_date, quantity, amount, region_id) VALUES
(101, 1, 10, '01-FEB-2023', 2, 150.00, 1),
(102, 2, 20, '15-MAR-2023', 3, 200.00, 2),
(103, 3, 30, '30-JUN-2023', 1, 500.00, 3);

-- Sample data insertion for fact_sales
INSERT INTO fact_sales (transaction_id, customer_id, product_id, transaction_date, amount, region_id) VALUES
(1001, 1, 10, '01-JAN-2023', 200.00, 1),
(1002, 2, 20, '15-JAN-2023', 300.00, 4),
(1003, 3, 30, '30-JAN-2023', 500.00, 7);

-- Sample data insertion for fact_log
INSERT INTO fact_log (log_id, user_id, log_time, action, details) VALUES
(1, 100, '01-JAN-2023 01:00:00', 'LOGIN', 'User logged in'),
(2, 100, '01-JAN-2023 02:00:00', 'LOGOUT', 'User logged out'),
(3, 101, '01-JAN-2023 03:00:00', 'UPDATE', 'Profile updated');

-- Sample data insertion for fact_transaction
INSERT INTO fact_transaction (transaction_id, customer_id, transaction_date, amount, region_id) VALUES
(1, 1, '01-JAN-2023', 100.00, 1),
(2, 2, '15-MAR-2023', 200.00, 2),
(3, 3, '30-JUN-2023', 300.00, 3);

-- Indexing example for partitioned tables. It's important to index on partition columns for optimal performance.

CREATE INDEX idx_order_date ON fact_order(order_date);

-- Query Examples to demonstrate benefits of partitioning

-- 1. Query that benefits from Range Partitioning
SELECT SUM(amount) AS total_sales
FROM fact_order
WHERE order_date BETWEEN '01-JAN-2023' AND '31-MAR-2023';

-- 2. Query that benefits from List Partitioning
SELECT COUNT(*) AS north_customers
FROM dim_customer
WHERE region_id IN (1,2,3);

-- 3. Query that benefits from Hash Partitioning
SELECT user_id, COUNT(*) AS login_count
FROM fact_log
WHERE action = 'LOGIN'
GROUP BY user_id;

-- 4. Query that benefits from Composite Partitioning
SELECT region_id, SUM(amount) AS total_sales
FROM fact_transaction
WHERE transaction_date BETWEEN '01-JAN-2023' AND '30-JUN-2023'
GROUP BY region_id;

-- Explanation and Expected Output:

/*
This script covers different partitioning strategies in SQL for optimizing data warehouses. Each partitioning method (Range, List, Hash, Composite) has its own use case and benefits.

Key points:

- RANGE Partitioning: 
    - Based on ranges of values (e.g., date ranges)
    - Useful for time-based queries
    - Example in fact_order table

- LIST Partitioning: 
    - Groups data based on specific values (e.g., regions, categories)
    - Useful when you can define explicit groups
    - Example in fact_sales table

- HASH Partitioning: 
    - Distributes data evenly based on a hash of the partition key
    - Useful for load balancing and parallel processing
    - Example in fact_log table

- COMPOSITE Partitioning: 
    - Combination of Range and List/HASH partitioning
    - Useful for multi-dimensional data (e.g., date and region)
    - Example in fact_transaction table

Important considerations:

1. Choose the right partition key based on your query patterns.
2. Avoid having too many partitions to prevent management overhead.
3. Monitor partition performance and adjust as needed.
4. Use automatic segment creation where appropriate.
5. Consider indexing partitioned columns for optimal performance.

Remember to always align your partitioning strategy with your business needs and query patterns to maximize performance and maintainability.

The script includes sample data insertion and queries to demonstrate how these partitions can be utilized effectively in a real-world data warehouse environment.
*/

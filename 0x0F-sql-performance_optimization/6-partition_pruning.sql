-- File: 6-partition_pruning.sql
-- Topic: Partition pruning
-- Description: Examples of using table partitioning to improve query performance

/*
 * Partition Pruning Examples
 *
 * This file demonstrates how to use table partitioning and achieve partition pruning
 */

-- Example 1: Creating a range partitioned table
CREATE TABLE sales (
    sale_id INT,
    sale_date DATE,
    sale_amount DECIMAL
)
PARTITION BY RANGE (sale_date);

-- Create partitions for each year
CREATE TABLE sales_2021 PARTITION OF sales
FOR VALUES FROM ('2021-01-01') TO ('2022-01-01');

CREATE TABLE sales_2022 PARTITION OF sales
FOR VALUES FROM ('2022-01-01') TO ('2023-01-01');

-- Example 2: Querying a partitioned table
-- This query will only scan the 2022 partition
SELECT * FROM sales
WHERE sale_date >= '2022-01-01' AND sale_date < '2023-01-01';

-- Example 3: Ensuring proper partitioning for query patterns
-- Partition based on the most frequent query filter
CREATE TABLE sales (
    sale_id INT,
    sale_region VARCHAR,
    sale_amount DECIMAL
)
PARTITION BY LIST (sale_region);

CREATE TABLE sales_na PARTITION OF sales
FOR VALUES IN ('NA');

CREATE TABLE sales_eu PARTITION OF sales
FOR VALUES IN ('EU');

-- Example 4: Monitoring partition usage
SELECT * FROM pg_partitions
WHERE tablename = 'sales';

-- Example 5: Using composite partitioning
CREATE TABLE sales (
    sale_id INT,
    sale_date DATE,
    sale_region VARCHAR
)
PARTITION BY RANGE (sale_date) SUBPARTITION BY LIST (sale_region);

-- Example 6: Avoiding full table scans
-- With proper partitioning and query filter
EXPLAIN SELECT * FROM sales
WHERE sale_date >= '2022-01-01' AND sale_region = 'NA';

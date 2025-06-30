-- File: 102-scalability_patterns.sql
-- Topic: Scalability patterns
-- Description: Examples of scalability patterns for high-performance databases

/*
 * Scalability Patterns
 *
 * This file demonstrates scalability patterns for high-performance databases
 */

-- Example 1: Connection pooling
-- Use connection pooling to improve scalability
CREATE POOL test_pool (
    maxconn = 100,
    reserve = 10
);

-- Example 2: Read/write splitting
-- Use separate databases for reads and writes
CREATE TABLE order_write (
    order_id INT,
    order_date DATE,
    order_total DECIMAL
);

-- Example 3: Sharding by range or hash
-- Shard by order_date
CREATE TABLE orders_2023 (
    CHECK (order_date >= '2023-01-01' AND order_date < '2024-01-01')
) INHERITS (orders);

-- Example 4: Replication for high availability
-- Set up streaming replication
SELECT * FROM pg_stat_replication;

-- Example 5: Load balancing across nodes
-- Use a load balancer to distribute queries

-- Example 6: Horizontal scaling with partitioning
-- Use list partitioning for regional data
CREATE TABLE sales_na PARTITION OF sales
FOR VALUES IN ('NA');

-- Example 7: Vertical scaling by offloading
-- Offload reporting to a separate database

-- Example 8: Monitoring scalability metrics
-- Scale metrics like query response time, throughput, and error rates
SELECT 
    date, 
    max_response_time, 
    avg_response_time, 
    throughput 
FROM performance_metrics
WHERE date >= CURRENT_DATE - INTERVAL '1 week';

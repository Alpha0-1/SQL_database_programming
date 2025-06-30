-- File: 101-hardware_considerations.sql
-- Topic: Hardware optimization
-- Description: Examples and recommendations for hardware optimization

/*
 * Hardware Considerations for Performance Optimization
 *
 * This file provides examples and recommendations for hardware optimization
 */

-- Example 1: Choosing the right storage
-- Use SSDs for tables with high read/write activity
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    order_date DATE,
    order_total DECIMAL(10,2)
)
-- Example 2: Using RAID configurations
-- Use RAID 10 for redundancy and performance

-- Example 3: Memory sizing
-- Calculate shared_buffers based on system memory
SELECT 
    (installed_memory * 0.25) AS shared_buffers_recommendation,
    (installed_memory * 0.75) AS effective_cache_size_recommendation
FROM 
    (SELECT pg_size_pretty(pg_total_memory() / 1024 / 1024) as installed_memory) tbl;

-- Example 4: CPU considerations
-- Use multi-core processors for parallel queries
SET max_parallel_workers = 8;

-- Example 5: Network optimization
-- Use low-latency network interfaces for distributed queries

-- Example 6: Monitoring hardware performance
SELECT 
    date, 
    cpu_usage, 
    memory_usage, 
    disk_usage 
FROM hardware_monitoring
WHERE date >= CURRENT_DATE - INTERVAL '1 day';

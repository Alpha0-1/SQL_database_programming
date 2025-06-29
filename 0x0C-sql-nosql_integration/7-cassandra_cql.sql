-- =====================================================
-- File: 7-cassandra_cql.sql
-- Description: Cassandra CQL examples and patterns
-- Author: Alpha0-1
-- =====================================================

-- Problem Statement: Demonstrate Cassandra CQL (Cassandra Query Language)
-- for wide-column store operations, time-series data, and distributed systems

-- Note: This file shows CQL syntax (similar to SQL) but optimized for Cassandra's
-- distributed, column-family data model

-- =====================================================
-- 1. KEYSPACE CREATION AND CONFIGURATION
-- =====================================================

-- Create keyspace (equivalent to database in SQL)
-- Keyspace defines replication strategy and data centers
CREATE KEYSPACE IF NOT EXISTS ecommerce_analytics
WITH REPLICATION = {
    'class': 'NetworkTopologyStrategy',
    'datacenter1': 3,  -- 3 replicas in datacenter1
    'datacenter2': 2   -- 2 replicas in datacenter2
}
AND DURABLE_WRITES = true;

-- Use the keyspace
USE ecommerce_analytics;

-- Alternative: Simple replication for single datacenter
-- CREATE KEYSPACE ecommerce_simple
-- WITH REPLICATION = {
--     'class': 'SimpleStrategy',
--     'replication_factor': 3
-- };

-- =====================================================
-- 2. TIME-SERIES DATA MODELING
-- =====================================================

-- User activity tracking (time-series pattern)
CREATE TABLE user_activity (
    user_id UUID,
    activity_date DATE,
    activity_time TIMESTAMP,
    activity_type TEXT,
    page_url TEXT,
    user_agent TEXT,
    ip_address INET,
    session_id UUID,
    duration_ms BIGINT,
    -- Partition key: user_id and activity_date for time-based queries
    -- Clustering key: activity_time for chronological ordering
    PRIMARY KEY ((user_id, activity_date), activity_time)
) WITH CLUSTERING ORDER BY (activity_time DESC)
-- Table-level options for performance optimization
AND COMPACTION = {
    'class': 'TimeWindowCompactionStrategy',
    'compaction_window_unit': 'DAYS',
    'compaction_window_size': 1
}
AND gc_grace_seconds = 86400;  -- 1 day for tombstone cleanup

-- Product sales metrics (wide-row pattern)
CREATE TABLE product_sales_daily (
    product_id UUID,
    sale_date DATE,
    hour INT,
    total_sales DECIMAL,
    units_sold COUNTER,
    unique_customers COUNTER,
    revenue COUNTER,
    PRIMARY KEY ((product_id, sale_date), hour)
) WITH CLUSTERING ORDER BY (hour ASC);

-- Real-time inventory tracking
CREATE TABLE inventory_events (
    product_id UUID,
    event_id TIMEUUID,
    event_type TEXT,  -- 'purchase', 'restock', 'adjustment'
    quantity_change INT,
    current_stock INT,
    warehouse_id UUID,
    created_at TIMESTAMP,
    metadata MAP<TEXT, TEXT>,
    PRIMARY KEY (product_id, event_id)
) WITH CLUSTERING ORDER BY (event_id DESC);

-- =====================================================
-- 3. USER AND SESSION MANAGEMENT
-- =====================================================

-- User profiles (entity table)
CREATE TABLE users (
    user_id UUID PRIMARY KEY,
    username TEXT,
    email TEXT,
    first_name TEXT,
    last_name TEXT,
    date_of_birth DATE,
    registration_date TIMESTAMP,
    last_login TIMESTAMP,
    status TEXT,
    preferences MAP<TEXT, TEXT>,
    tags SET<TEXT>,
    addresses LIST<FROZEN<address_type>>
);

-- User defined type for addresses
CREATE TYPE IF NOT EXISTS address_type (
    street TEXT,
    city TEXT,
    state TEXT,
    zip_code TEXT,
    country TEXT,
    address_type TEXT  -- 'home', 'work', 'billing'
);

-- User sessions with TTL (automatic expiration)
CREATE TABLE user_sessions (
    session_id UUID PRIMARY KEY,
    user_id UUID,
    created_at TIMESTAMP,
    last_activity TIMESTAMP,
    ip_address INET,
    user_agent TEXT,
    session_data MAP<TEXT, TEXT>,
    is_active BOOLEAN
) WITH default_time_to_live = 86400;  -- 24 hours TTL

-- Email lookup table (secondary index pattern)
CREATE TABLE users_by_email (
    email TEXT PRIMARY KEY,
    user_id UUID,
    username TEXT,
    created_at TIMESTAMP
);

-- =====================================================
-- 4. PRODUCT CATALOG AND REVIEWS
-- =====================================================

-- Product catalog
CREATE TABLE products (
    product_id UUID PRIMARY KEY,
    name TEXT,
    description TEXT,
    category TEXT,
    brand TEXT,
    price DECIMAL,
    attributes MAP<TEXT, TEXT>,
    tags SET<TEXT>,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    is_active BOOLEAN
);

-- Product reviews (one-to-many relationship)
CREATE TABLE product_reviews (
    product_id UUID,
    review_id TIMEUUID,
    user_id UUID,
    rating INT,
    title TEXT,
    content TEXT,
    helpful_count COUNTER,
    verified_purchase BOOLEAN,
    created_at TIMESTAMP,
    PRIMARY KEY (product_id, review_id)
) WITH CLUSTERING ORDER BY (review_id DESC);

-- Product categories (hierarchical data)
CREATE TABLE product_categories (
    category_id UUID,
    parent_category_id UUID,
    category_name TEXT,
    level INT,
    path LIST<TEXT>,  -- breadcrumb path
    product_count COUNTER,
    created_at TIMESTAMP,
    PRIMARY KEY (category_id)
);

-- =====================================================
-- 5. ORDERS AND TRANSACTIONS
-- =====================================================

-- Orders table
CREATE TABLE orders (
    order_id UUID PRIMARY KEY,
    user_id UUID,
    order_status TEXT,
    order_date TIMESTAMP,
    total_amount DECIMAL,
    shipping_address FROZEN<address_type>,
    billing_address FROZEN<address_type>,
    payment_method TEXT,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

-- Order items (separate table for normalization)
CREATE TABLE order_items (
    order_id UUID,
    item_id UUID,
    product_id UUID,
    product_name TEXT,
    quantity INT,
    unit_price DECIMAL,
    total_price DECIMAL,
    PRIMARY KEY (order_id, item_id)
);

-- Orders by user (query optimization table)
CREATE TABLE orders_by_user (
    user_id UUID,
    order_date DATE,
    order_id UUID,
    order_status TEXT,
    total_amount DECIMAL,
    PRIMARY KEY ((user_id, order_date), order_id)
) WITH CLUSTERING ORDER BY (order_id DESC);

-- =====================================================
-- 6. ANALYTICS AND REPORTING TABLES
-- =====================================================

-- Daily sales summary
CREATE TABLE daily_sales (
    sale_date DATE,
    category TEXT,
    total_revenue COUNTER,
    total_orders COUNTER,
    unique_customers COUNTER,
    avg_order_value DECIMAL,
    top_products LIST<UUID>,
    updated_at TIMESTAMP,
    PRIMARY KEY (sale_date, category)
);

-- User behavior analytics
CREATE TABLE user_behavior_summary (
    user_id UUID,
    behavior_date DATE,
    page_views COUNTER,
    session_duration BIGINT,
    purchases_count COUNTER,
    revenue_generated DECIMAL,
    last_activity TIMESTAMP,
    PRIMARY KEY (user_id, behavior_date)
) WITH CLUSTERING ORDER BY (behavior_date DESC);

-- Real-time metrics (sliding window)
CREATE TABLE real_time_metrics (
    metric_name TEXT,
    time_bucket TIMESTAMP,  -- rounded to 5-minute intervals
    metric_value DOUBLE,
    tags MAP<TEXT, TEXT>,
    PRIMARY KEY (metric_name, time_bucket)
) WITH CLUSTERING ORDER BY (time_bucket DESC)
AND default_time_to_live = 604800;  -- 7 days TTL

-- =====================================================
-- 7. DATA INSERTION EXAMPLES
-- =====================================================

-- Insert user with UUID generation
INSERT INTO users (
    user_id, username, email, first_name, last_name,
    registration_date, status, preferences, tags
) VALUES (
    uuid(), 'john_doe', 'john@example.com', 'John', 'Doe',
    toTimestamp(now()), 'active',
    {'theme': 'dark', 'notifications': 'email'},
    {'premium', 'early_adopter'}
);

-- Insert user session with TTL
INSERT INTO user_sessions (
    session_id, user_id, created_at, last_activity,
    ip_address, user_agent, session_data, is_active
) VALUES (
    uuid(), uuid(), toTimestamp(now()), toTimestamp(now()),
    '192.168.1.100', 'Mozilla/5.0...',
    {'login_method': 'oauth', 'referrer': 'google'},
    true
) USING TTL 3600;  -- 1 hour TTL override

-- Insert activity with time-series pattern
INSERT INTO user_activity (
    user_id, activity_date, activity_time, activity_type,
    page_url, user_agent, ip_address, session_id, duration_ms
) VALUES (
    uuid(), '2024-01-15', toTimestamp(now()), 'page_view',
    '/products/laptop', 'Mozilla/5.0...', '192.168.1.100',
    uuid(), 15000
);

-- Update counters (atomic operations)
UPDATE product_sales_daily
SET units_sold = units_sold + 1,
    revenue = revenue + 99999  -- price in cents
WHERE product_id = uuid() AND sale_date = '2024-01-15' AND hour = 14;

-- =====================================================
-- 8. QUERY PATTERNS AND EXAMPLES
-- =====================================================

-- Time-range queries (efficient with clustering)
SELECT activity_type, activity_time, page_url
FROM user_activity
WHERE user_id = uuid() 
  AND activity_date IN ('2024-01-15', '2024-01-16')
  AND activity_time > '2024-01-15 10:00:00'
  AND activity_time < '2024-01-15 18:00:00'
ORDER BY activity_time DESC;

-- Pagination with token
SELECT user_id, username, email
FROM users
WHERE token(user_id) > token(uuid())
LIMIT 100;

-- Collection operations
SELECT username, tags
FROM users
WHERE tags CONTAINS 'premium'
ALLOW FILTERING;  -- Use sparingly, can impact performance

-- Map and list operations
SELECT product_id, attributes['color'], attributes['size']
FROM products
WHERE attributes CONTAINS KEY 'color';

-- Counter queries
SELECT product_id, units_sold, revenue
FROM product_sales_daily
WHERE product_id = uuid()
  AND sale_date = '2024-01-15';

-- =====================================================
-- 9. BATCH OPERATIONS AND TRANSACTIONS
-- =====================================================

-- Batch statement for related operations
BEGIN BATCH
    INSERT INTO orders (order_id, user_id, order_status, order_date, total_amount)
    VALUES (uuid(), uuid(), 'pending', toTimestamp(now()), 299.99);
    
    INSERT INTO order_items (order_id, item_id, product_id, quantity, unit_price)
    VALUES (uuid(), uuid(), uuid(), 2, 149.99);
    
    UPDATE user_behavior_summary
    SET purchases_count = purchases_count + 1
    WHERE user_id = uuid() AND behavior_date = '2024-01-15';
APPLY BATCH;

-- Lightweight transaction (compare-and-set)
UPDATE users 
SET email = 'newemail@example.com'
WHERE user_id = uuid()
IF email = 'oldemail@example.com';

-- Conditional insert
INSERT INTO users (user_id, username, email)
VALUES (uuid(), 'new_user', 'user@example.com')
IF NOT EXISTS;

-- =====================================================
-- 10. MATERIALIZED VIEWS
-- =====================================================

-- Materialized view for different query patterns
CREATE MATERIALIZED VIEW products_by_category AS
    SELECT category, product_id, name, price, created_at
    FROM products
    WHERE category IS NOT NULL 
      AND product_id IS NOT NULL
      AND name IS NOT NULL
    PRIMARY KEY (category, created_at, product_id)
    WITH CLUSTERING ORDER BY (created_at DESC, product_id ASC);

-- Materialized view for user orders
CREATE MATERIALIZED VIEW recent_orders AS
    SELECT order_date, order_id, user_id, order_status, total_amount
    FROM orders
    WHERE order_date IS NOT NULL
      AND order_id IS NOT NULL
      AND user_id IS NOT NULL
    PRIMARY KEY (order_date, order_id)
    WITH CLUSTERING ORDER BY (order_id DESC);

-- =====================================================
-- 11. SECONDARY INDEXES
-- =====================================================

-- Secondary index on user status
CREATE INDEX ON users (status);

-- Secondary index on product category
CREATE INDEX ON products (category);

-- Secondary index on order status
CREATE INDEX ON orders (order_status);

-- Custom index on map values
CREATE INDEX ON products (VALUES(attributes));

-- =====================================================
-- 12. AGGREGATION AND ANALYTICS QUERIES
-- =====================================================

-- Daily sales aggregation (pre-computed)
SELECT sale_date, SUM(total_revenue), SUM(total_orders)
FROM daily_sales
WHERE sale_date >= '2024-01-01' AND sale_date <= '2024-01-31'
GROUP BY sale_date;

-- User activity analysis
SELECT user_id, SUM(page_views), AVG(session_duration)
FROM user_behavior_summary
WHERE behavior_date >= '2024-01-01'
  AND behavior_date <= '2024-01-07'
GROUP BY user_id;

-- Product performance metrics
SELECT product_id, SUM(units_sold), SUM(revenue)
FROM product_sales_daily
WHERE sale_date = '2024-01-15'
GROUP BY product_id;

-- =====================================================
-- 13. DATA MODELING BEST PRACTICES
-- =====================================================

/*
Cassandra Data Modeling Principles:

1. Query-First Design:
   - Design tables based on query patterns
   - Denormalize data for read performance
   - Create multiple tables for different access patterns

2. Partition Key Selection:
   - Choose keys that distribute data evenly
   - Avoid hot partitions
   - Consider cardinality and access patterns

3. Clustering Key Design:
   - Order data within partitions
   - Enable range queries
   - Consider sort order requirements

4. Time-Series Patterns:
   - Use date/time in partition key
   - Bucket data appropriately
   - Consider TTL for automatic cleanup

5. Counter Columns:
   - Use for metrics and analytics
   - Atomic increment/decrement operations
   - Cannot be mixed with regular columns in PRIMARY KEY

6. Collection Types:
   - Use for denormalization
   - Limit collection size (< 64KB recommended)
   - Consider frozen collections for complex types

7. TTL (Time To Live):
   - Automatic data expiration
   - Useful for session data, caches
   - Can be set per row or column

8. Materialized Views:
   - Automatic denormalization
   - Different primary key from base table
   - Eventually consistent
*/

-- =====================================================
-- 14. MAINTENANCE AND OPERATIONS
-- =====================================================

-- Check table statistics
SELECT * FROM system.size_estimates 
WHERE keyspace_name = 'ecommerce_analytics';

-- Describe table structure
DESCRIBE TABLE users;

-- Check compaction status
-- nodetool compactionstats

-- Repair data consistency
-- nodetool repair ecommerce_analytics

-- Cleanup examples (CQL doesn't have direct cleanup, use nodetool)
-- nodetool cleanup ecommerce_analytics

-- Truncate table (removes all data)
-- TRUNCATE user_activity;

-- Drop materialized view
-- DROP MATERIALIZED VIEW products_by_category;

-- Drop table
-- DROP TABLE user_sessions;

-- Drop keyspace
-- DROP KEYSPACE ecommerce_analytics;

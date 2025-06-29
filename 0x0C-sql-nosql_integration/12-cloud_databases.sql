/*
 * File: 12-cloud_databases.sql
 * Description: Cloud Database Services Integration and Migration Patterns
 * Author: Alpha0-1
 * 
 * This file demonstrates working with various cloud database services
 * including AWS RDS, Azure SQL, Google Cloud SQL, and migration patterns
 */

-- =============================================================================
-- SECTION 1: AWS RDS Configuration and Setup
-- =============================================================================

/*
 * AWS RDS PostgreSQL setup with read replicas
 * Demonstrates multi-AZ deployment for high availability
 */

-- Create database with cloud-optimized settings
CREATE DATABASE ecommerce_aws
    WITH 
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TEMPLATE = template0;

-- Table optimized for AWS RDS with proper indexing
CREATE TABLE IF NOT EXISTS products_aws (
    product_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    category_id INTEGER,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes optimized for cloud performance
CREATE INDEX CONCURRENTLY idx_products_aws_category ON products_aws(category_id);
CREATE INDEX CONCURRENTLY idx_products_aws_metadata_gin ON products_aws USING GIN(metadata);
CREATE INDEX CONCURRENTLY idx_products_aws_created_at ON products_aws(created_at DESC);

-- =============================================================================
-- SECTION 2: Azure SQL Database Features
-- =============================================================================

/*
 * Azure SQL Database specific features and optimizations
 * Includes temporal tables and Azure-specific functions
 */

-- Azure SQL temporal table for audit trail
CREATE TABLE orders_azure (
    order_id INT IDENTITY(1,1) PRIMARY KEY,
    customer_id INT NOT NULL,
    order_date DATETIME2 NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    
    -- Temporal table columns for Azure SQL
    valid_from DATETIME2 GENERATED ALWAYS AS ROW START HIDDEN,
    valid_to DATETIME2 GENERATED ALWAYS AS ROW END HIDDEN,
    PERIOD FOR SYSTEM_TIME (valid_from, valid_to)
) WITH (SYSTEM_VERSIONING = ON);

-- Azure SQL Database query with performance insights
SELECT 
    o.order_id,
    o.customer_id,
    o.total_amount,
    o.status,
    -- Azure-specific function for date handling
    FORMAT(o.order_date, 'yyyy-MM-dd') as formatted_date
FROM orders_azure o
WHERE o.order_date >= DATEADD(month, -3, GETDATE())
ORDER BY o.order_date DESC;

-- =============================================================================
-- SECTION 3: Google Cloud SQL BigQuery Integration
-- =============================================================================

/*
 * Google Cloud SQL with BigQuery federation
 * Demonstrates cross-service querying capabilities
 */

-- Standard SQL for Cloud SQL
CREATE TABLE analytics_events (
    event_id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id VARCHAR(50) NOT NULL,
    event_type VARCHAR(100) NOT NULL,
    event_data JSONB,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    session_id VARCHAR(100),
    device_info JSONB
);

-- Partition table for better performance in cloud environment
CREATE TABLE sales_data_partitioned (
    sale_id BIGSERIAL,
    product_id INTEGER NOT NULL,
    customer_id INTEGER NOT NULL,
    sale_amount DECIMAL(12,2) NOT NULL,
    sale_date DATE NOT NULL,
    region VARCHAR(50) NOT NULL
) PARTITION BY RANGE (sale_date);

-- Create partitions for different months
CREATE TABLE sales_2024_q1 PARTITION OF sales_data_partitioned
    FOR VALUES FROM ('2024-01-01') TO ('2024-04-01');

CREATE TABLE sales_2024_q2 PARTITION OF sales_data_partitioned
    FOR VALUES FROM ('2024-04-01') TO ('2024-07-01');

-- =============================================================================
-- SECTION 4: Multi-Cloud Data Synchronization
-- =============================================================================

/*
 * Patterns for synchronizing data across multiple cloud providers
 * Using stored procedures and triggers for real-time sync
 */

-- Create sync log table for tracking changes
CREATE TABLE sync_log (
    sync_id SERIAL PRIMARY KEY,
    table_name VARCHAR(100) NOT NULL,
    operation VARCHAR(10) NOT NULL, -- INSERT, UPDATE, DELETE
    record_id VARCHAR(100) NOT NULL,
    sync_status VARCHAR(20) DEFAULT 'pending',
    cloud_provider VARCHAR(50) NOT NULL,
    sync_timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    error_message TEXT
);

-- Trigger function for automatic sync logging
CREATE OR REPLACE FUNCTION log_data_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO sync_log (table_name, operation, record_id, cloud_provider)
        VALUES (TG_TABLE_NAME, 'INSERT', NEW.product_id::text, 'primary');
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO sync_log (table_name, operation, record_id, cloud_provider)
        VALUES (TG_TABLE_NAME, 'UPDATE', NEW.product_id::text, 'primary');
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO sync_log (table_name, operation, record_id, cloud_provider)
        VALUES (TG_TABLE_NAME, 'DELETE', OLD.product_id::text, 'primary');
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to products table
CREATE TRIGGER products_sync_trigger
    AFTER INSERT OR UPDATE OR DELETE ON products_aws
    FOR EACH ROW EXECUTE FUNCTION log_data_changes();

-- =============================================================================
-- SECTION 5: Cloud Database Migration Patterns
-- =============================================================================

/*
 * Database migration scripts for moving between cloud providers
 * Includes data type mapping and constraint handling
 */

-- Migration staging table with universal data types
CREATE TABLE migration_staging (
    id BIGINT NOT NULL,
    string_data TEXT,
    numeric_data DECIMAL(20,6),
    date_data TIMESTAMP WITH TIME ZONE,
    json_data JSONB,
    binary_data BYTEA,
    boolean_data BOOLEAN,
    source_system VARCHAR(50),
    migration_batch_id UUID DEFAULT gen_random_uuid()
);

-- Migration validation query
WITH migration_summary AS (
    SELECT 
        source_system,
        COUNT(*) as record_count,
        MIN(date_data) as earliest_date,
        MAX(date_data) as latest_date,
        COUNT(DISTINCT migration_batch_id) as batch_count
    FROM migration_staging
    GROUP BY source_system
)
SELECT 
    ms.*,
    CASE 
        WHEN record_count > 0 THEN 'Ready for migration'
        ELSE 'No data to migrate'
    END as migration_status
FROM migration_summary ms;

-- =============================================================================
-- SECTION 6: Cloud Database Performance Monitoring
-- =============================================================================

/*
 * Performance monitoring queries for cloud databases
 * Adapted for different cloud provider metrics
 */

-- Generic performance monitoring view
CREATE OR REPLACE VIEW cloud_performance_metrics AS
SELECT 
    schemaname,
    tablename,
    n_tup_ins as inserts,
    n_tup_upd as updates,
    n_tup_del as deletes,
    n_tup_hot_upd as hot_updates,
    n_live_tup as live_tuples,
    n_dead_tup as dead_tuples,
    ROUND(
        CASE 
            WHEN n_live_tup > 0 
            THEN (n_dead_tup::float / n_live_tup::float) * 100 
            ELSE 0 
        END, 2
    ) as dead_tuple_percentage
FROM pg_stat_user_tables
WHERE n_live_tup > 0;

-- Cloud-optimized connection pooling query
SELECT 
    datname as database_name,
    usename as username,
    client_addr,
    state,
    COUNT(*) as connection_count,
    AVG(EXTRACT(EPOCH FROM (now() - state_change))) as avg_state_duration
FROM pg_stat_activity 
WHERE state IS NOT NULL
GROUP BY datname, usename, client_addr, state
ORDER BY connection_count DESC;

-- =============================================================================
-- SECTION 7: Example Usage and Testing
-- =============================================================================

/*
 * Example data insertion and querying for cloud databases
 */

-- Insert test data
INSERT INTO products_aws (name, description, price, category_id, metadata) VALUES
('Cloud Widget Pro', 'High-performance widget for cloud applications', 299.99, 1, 
 '{"features": ["scalable", "secure", "monitored"], "cloud_optimized": true}'),
('Data Sync Tool', 'Multi-cloud data synchronization utility', 149.99, 2,
 '{"supports": ["AWS", "Azure", "GCP"], "real_time": true}'),
('Analytics Dashboard', 'Cloud-native analytics solution', 199.99, 3,
 '{"integrations": ["BigQuery", "Redshift", "Synapse"], "visualization": true}');

-- Query with cloud-specific optimizations
EXPLAIN (ANALYZE, BUFFERS) 
SELECT 
    p.name,
    p.price,
    p.metadata->>'cloud_optimized' as is_cloud_optimized,
    jsonb_array_elements_text(p.metadata->'features') as features
FROM products_aws p
WHERE p.metadata ? 'cloud_optimized'
  AND p.price BETWEEN 100 AND 300
ORDER BY p.price DESC;

/*
 * Notes for Implementation:
 * 
 * 1. AWS RDS Setup:
 *    - Configure parameter groups for optimal performance
 *    - Set up read replicas for read scaling
 *    - Enable automated backups and point-in-time recovery
 * 
 * 2. Azure SQL Database:
 *    - Use elastic pools for cost optimization
 *    - Configure temporal tables for audit requirements
 *    - Implement intelligent insights for performance tuning
 * 
 * 3. Google Cloud SQL:
 *    - Enable high availability and automatic failover
 *    - Use BigQuery federated queries for analytics
 *    - Configure Cloud SQL proxy for secure connections
 * 
 * 4. Migration Best Practices:
 *    - Test migrations in staging environments
 *    - Use parallel processing for large datasets
 *    - Implement rollback procedures
 *    - Monitor performance during migration
 */

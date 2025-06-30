-- =====================================================
-- File: 8-etl_workflows.sql
-- Description: ETL (Extract, Transform, Load) workflow examples
-- Author: Alpha0-1
-- =====================================================

-- ETL workflows are the backbone of data warehousing
-- This file demonstrates various ETL patterns and techniques

-- =====================================================
-- EXTRACT PHASE EXAMPLES
-- =====================================================

-- Example 1: Extract from multiple source systems
-- Creating staging tables to hold extracted data
CREATE TABLE staging_customers (
    customer_id INT,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    registration_date DATE,
    source_system VARCHAR(20),
    extract_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE staging_orders (
    order_id INT,
    customer_id INT,
    order_date DATE,
    order_amount DECIMAL(10,2),
    order_status VARCHAR(20),
    source_system VARCHAR(20),
    extract_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Extract query example (would be run by ETL tool)
-- This simulates extracting data from operational systems
INSERT INTO staging_customers 
SELECT 
    customer_id,
    first_name,
    last_name,
    email,
    registration_date,
    'CRM_SYSTEM' as source_system,
    CURRENT_TIMESTAMP as extract_timestamp
FROM source_crm.customers 
WHERE last_modified_date >= '2025-06-29';

-- =====================================================
-- TRANSFORM PHASE EXAMPLES
-- =====================================================

-- Example 2: Data cleansing and standardization
CREATE TABLE cleaned_customers AS
SELECT 
    customer_id,
    -- Standardize names (title case)
    INITCAP(TRIM(first_name)) as first_name,
    INITCAP(TRIM(last_name)) as last_name,
    -- Standardize email (lowercase)
    LOWER(TRIM(email)) as email,
    registration_date,
    -- Data quality flags
    CASE 
        WHEN email IS NULL OR email = '' THEN 'MISSING_EMAIL'
        WHEN email NOT LIKE '%@%.%' THEN 'INVALID_EMAIL'
        ELSE 'VALID'
    END as data_quality_flag,
    source_system,
    extract_timestamp
FROM staging_customers
WHERE customer_id IS NOT NULL;

-- Example 3: Business rule transformations
CREATE TABLE transformed_orders AS
SELECT 
    o.order_id,
    o.customer_id,
    o.order_date,
    o.order_amount,
    -- Business categorization
    CASE 
        WHEN o.order_amount < 100 THEN 'Small'
        WHEN o.order_amount BETWEEN 100 AND 500 THEN 'Medium'
        WHEN o.order_amount > 500 THEN 'Large'
        ELSE 'Unknown'
    END as order_category,
    -- Calculate order processing time
    CASE 
        WHEN o.order_status = 'Shipped' THEN 
            DATEDIFF(day, o.order_date, CURRENT_DATE)
        ELSE NULL
    END as processing_days,
    o.order_status,
    o.source_system,
    o.extract_timestamp
FROM staging_orders o;

-- =====================================================
-- LOAD PHASE EXAMPLES
-- =====================================================

-- Example 4: Slowly Changing Dimension (SCD Type 2) Load
-- This maintains historical changes in dimension data
CREATE OR REPLACE PROCEDURE load_customer_dimension()
BEGIN
    -- Insert new customers
    INSERT INTO dim_customer (
        customer_key,
        customer_id,
        first_name,
        last_name,
        email,
        effective_date,
        expiry_date,
        is_current
    )
    SELECT 
        NEXT VALUE FOR customer_key_seq,
        sc.customer_id,
        sc.first_name,
        sc.last_name,
        sc.email,
        CURRENT_DATE,
        '9999-12-31',
        'Y'
    FROM cleaned_customers sc
    WHERE NOT EXISTS (
        SELECT 1 FROM dim_customer dc 
        WHERE dc.customer_id = sc.customer_id
    );
    
    -- Handle changed customers (SCD Type 2)
    -- First, expire old records
    UPDATE dim_customer 
    SET expiry_date = CURRENT_DATE - 1,
        is_current = 'N'
    WHERE customer_id IN (
        SELECT DISTINCT sc.customer_id
        FROM cleaned_customers sc
        JOIN dim_customer dc ON sc.customer_id = dc.customer_id
        WHERE dc.is_current = 'Y'
        AND (sc.first_name != dc.first_name 
             OR sc.last_name != dc.last_name 
             OR sc.email != dc.email)
    );
    
    -- Insert new versions of changed records
    INSERT INTO dim_customer (
        customer_key,
        customer_id,
        first_name,
        last_name,
        email,
        effective_date,
        expiry_date,
        is_current
    )
    SELECT 
        NEXT VALUE FOR customer_key_seq,
        sc.customer_id,
        sc.first_name,
        sc.last_name,
        sc.email,
        CURRENT_DATE,
        '9999-12-31',
        'Y'
    FROM cleaned_customers sc
    JOIN dim_customer dc ON sc.customer_id = dc.customer_id
    WHERE dc.is_current = 'N'
    AND dc.expiry_date = CURRENT_DATE - 1;
    
END;

-- =====================================================
-- INCREMENTAL LOADING PATTERNS
-- =====================================================

-- Example 5: Delta/Incremental load for fact tables
CREATE OR REPLACE PROCEDURE incremental_fact_load()
BEGIN
    DECLARE last_load_date DATE;
    
    -- Get last successful load date
    SELECT MAX(load_date) INTO last_load_date 
    FROM etl_log 
    WHERE table_name = 'fact_orders' 
    AND status = 'SUCCESS';
    
    -- Default to yesterday if no previous load
    IF last_load_date IS NULL THEN
        SET last_load_date = CURRENT_DATE - 1;
    END IF;
    
    -- Load only new/changed orders since last load
    INSERT INTO fact_orders (
        order_key,
        customer_key,
        date_key,
        order_id,
        order_amount,
        order_category,
        processing_days,
        load_date
    )
    SELECT 
        NEXT VALUE FOR order_key_seq,
        dc.customer_key,
        dd.date_key,
        to.order_id,
        to.order_amount,
        to.order_category,
        to.processing_days,
        CURRENT_DATE
    FROM transformed_orders to
    JOIN dim_customer dc ON to.customer_id = dc.customer_id 
        AND dc.is_current = 'Y'
    JOIN dim_date dd ON to.order_date = dd.full_date
    WHERE to.order_date > last_load_date
    AND NOT EXISTS (
        SELECT 1 FROM fact_orders fo 
        WHERE fo.order_id = to.order_id
    );
    
    -- Log successful load
    INSERT INTO etl_log (table_name, load_date, records_loaded, status)
    VALUES ('fact_orders', CURRENT_DATE, ROW_COUNT(), 'SUCCESS');
    
END;

-- =====================================================
-- ERROR HANDLING AND DATA QUALITY
-- =====================================================

-- Example 6: ETL with error handling and logging
CREATE TABLE etl_errors (
    error_id INT AUTO_INCREMENT PRIMARY KEY,
    job_name VARCHAR(100),
    table_name VARCHAR(100),
    error_message TEXT,
    error_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    record_data JSON
);

CREATE OR REPLACE PROCEDURE robust_etl_load()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE error_count INT DEFAULT 0;
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            @error_message = MESSAGE_TEXT;
        INSERT INTO etl_errors (job_name, table_name, error_message)
        VALUES ('customer_etl', 'staging_customers', @error_message);
        SET error_count = error_count + 1;
    END;
    
    -- Begin transaction
    START TRANSACTION;
    
    -- Validate data before processing
    INSERT INTO etl_errors (job_name, table_name, error_message, record_data)
    SELECT 
        'customer_etl',
        'staging_customers',
        'Missing required field',
        JSON_OBJECT('customer_id', customer_id, 'email', email)
    FROM staging_customers
    WHERE email IS NULL OR email = '';
    
    -- Delete invalid records
    DELETE FROM staging_customers 
    WHERE email IS NULL OR email = '';
    
    -- Process valid records
    CALL load_customer_dimension();
    
    -- Check if errors occurred
    IF error_count > 0 THEN
        ROLLBACK;
        INSERT INTO etl_log (table_name, load_date, status, error_message)
        VALUES ('dim_customer', CURRENT_DATE, 'FAILED', 
                CONCAT('Errors encountered: ', error_count));
    ELSE
        COMMIT;
        INSERT INTO etl_log (table_name, load_date, status)
        VALUES ('dim_customer', CURRENT_DATE, 'SUCCESS');
    END IF;
    
END;

-- =====================================================
-- ETL ORCHESTRATION EXAMPLE
-- =====================================================

-- Example 7: Master ETL workflow orchestration
CREATE OR REPLACE PROCEDURE master_etl_workflow()
BEGIN
    DECLARE workflow_status VARCHAR(20) DEFAULT 'RUNNING';
    
    -- Log workflow start
    INSERT INTO etl_log (table_name, load_date, status)
    VALUES ('master_workflow', CURRENT_DATE, 'STARTED');
    
    -- Step 1: Extract and stage data
    BEGIN
        CALL extract_customer_data();
        CALL extract_order_data();
    END;
    
    -- Step 2: Data quality validation
    BEGIN
        CALL validate_staging_data();
    END;
    
    -- Step 3: Transform data
    BEGIN
        CALL transform_customer_data();
        CALL transform_order_data();
    END;
    
    -- Step 4: Load dimensions (order matters!)
    BEGIN
        CALL load_customer_dimension();
        CALL load_date_dimension();
    END;
    
    -- Step 5: Load facts
    BEGIN
        CALL incremental_fact_load();
    END;
    
    -- Step 6: Update aggregates
    BEGIN
        CALL refresh_aggregate_tables();
    END;
    
    -- Log workflow completion
    INSERT INTO etl_log (table_name, load_date, status)
    VALUES ('master_workflow', CURRENT_DATE, 'COMPLETED');
    
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO etl_log (table_name, load_date, status, error_message)
        VALUES ('master_workflow', CURRENT_DATE, 'FAILED', SQLERRM);
        RAISE;
END;

-- =====================================================
-- MONITORING AND LOGGING TABLES
-- =====================================================

-- ETL monitoring table
CREATE TABLE etl_log (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    job_name VARCHAR(100),
    table_name VARCHAR(100),
    load_date DATE,
    start_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    end_time TIMESTAMP,
    records_processed INT,
    records_loaded INT,
    records_rejected INT,
    status VARCHAR(20), -- STARTED, RUNNING, SUCCESS, FAILED
    error_message TEXT
);

-- Data lineage tracking
CREATE TABLE data_lineage (
    lineage_id INT AUTO_INCREMENT PRIMARY KEY,
    source_table VARCHAR(100),
    target_table VARCHAR(100),
    transformation_rule TEXT,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- USAGE EXAMPLES AND TESTING
-- =====================================================

-- How to run the ETL workflow:
-- 1. Execute master workflow
-- CALL master_etl_workflow();

-- 2. Check ETL status
-- SELECT * FROM etl_log WHERE load_date = CURRENT_DATE ORDER BY start_time;

-- 3. Monitor data quality
-- SELECT * FROM etl_errors WHERE DATE(error_timestamp) = CURRENT_DATE;

-- 4. Validate loaded data
-- SELECT COUNT(*) as customer_count FROM dim_customer WHERE is_current = 'Y';
-- SELECT COUNT(*) as order_count FROM fact_orders WHERE load_date = CURRENT_DATE;

-- =====================================================
-- PERFORMANCE CONSIDERATIONS
-- =====================================================

-- 1. Use bulk operations instead of row-by-row processing
-- 2. Implement parallel processing where possible
-- 3. Use appropriate indexes on staging tables
-- 4. Consider partitioning for large datasets
-- 5. Implement checkpoints for long-running processes
-- 6. Use database-specific bulk loading utilities

-- Example indexes for performance
CREATE INDEX idx_staging_customers_modified ON staging_customers(extract_timestamp);
CREATE INDEX idx_staging_orders_date ON staging_orders(order_date);
CREATE INDEX idx_dim_customer_lookup ON dim_customer(customer_id, is_current);

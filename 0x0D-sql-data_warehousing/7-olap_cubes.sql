-- ============================================================================
-- File: 7-olap_cubes.sql
-- Description: OLAP Cube Concepts and Implementation
-- Author: Alpha0-1
-- Topic: Online Analytical Processing (OLAP) cubes and multidimensional analysis
-- ============================================================================

-- OLAP cubes provide multidimensional views of data for analytical processing
-- They support drill-down, roll-up, slice, dice, and pivot operations

-- ============================================================================
-- SCENARIO: Retail sales OLAP cube for multidimensional analysis
-- ============================================================================

-- Create schema for OLAP structures
CREATE SCHEMA IF NOT EXISTS olap_cube;

-- ============================================================================
-- 1. CUBE DIMENSION TABLES
-- ============================================================================

-- Time dimension with hierarchy (Year -> Quarter -> Month -> Day)
CREATE TABLE olap_cube.dim_time (
    time_key INT PRIMARY KEY,
    date_value DATE NOT NULL,
    day_of_week VARCHAR(10) NOT NULL,
    day_of_month INT NOT NULL,
    day_of_year INT NOT NULL,
    week_of_year INT NOT NULL,
    month_number INT NOT NULL,
    month_name VARCHAR(15) NOT NULL,
    quarter_number INT NOT NULL,
    quarter_name VARCHAR(10) NOT NULL,
    year_number INT NOT NULL,
    is_weekend BOOLEAN NOT NULL,
    is_holiday BOOLEAN DEFAULT FALSE,
    fiscal_year INT,
    fiscal_quarter INT,
    
    INDEX idx_year_quarter (year_number, quarter_number),
    INDEX idx_year_month (year_number, month_number),
    INDEX idx_date (date_value)
);

-- Product dimension with hierarchy (Category -> Subcategory -> Product)
CREATE TABLE olap_cube.dim_product (
    product_key INT PRIMARY KEY,
    product_id VARCHAR(20) NOT NULL,
    product_name VARCHAR(100) NOT NULL,
    product_level VARCHAR(20) DEFAULT 'Product', -- 'Product', 'Subcategory', 'Category'
    subcategory_id VARCHAR(20),
    subcategory_name VARCHAR(50),
    category_id VARCHAR(20),
    category_name VARCHAR(50),
    brand_name VARCHAR(50),
    unit_cost DECIMAL(8,2),
    unit_price DECIMAL(8,2),
    profit_margin DECIMAL(5,2),
    
    INDEX idx_category (category_name),
    INDEX idx_subcategory (subcategory_name),
    INDEX idx_brand (brand_name)
);

-- Geography dimension with hierarchy (Country -> Region -> State -> City)
CREATE TABLE olap_cube.dim_geography (
    geography_key INT PRIMARY KEY,
    geography_level VARCHAR(20) NOT NULL, -- 'City', 'State', 'Region', 'Country'
    city_name VARCHAR(50),
    state_code VARCHAR(5),
    state_name VARCHAR(50),
    region_name VARCHAR(50),
    country_code VARCHAR(5),
    country_name VARCHAR(50),
    population INT,
    area_sq_km DECIMAL(10,2),
    
    INDEX idx_country (country_name),
    INDEX idx_region (region_name),
    INDEX idx_state (state_name)
);

-- Customer dimension with hierarchy (All Customers -> Segment -> Individual)
CREATE TABLE olap_cube.dim_customer (
    customer_key INT PRIMARY KEY,
    customer_id VARCHAR(20),
    customer_name VARCHAR(100),
    customer_level VARCHAR(20) DEFAULT 'Individual', -- 'Individual', 'Segment', 'All'
    customer_segment VARCHAR(30),
    age_group VARCHAR(20),
    income_bracket VARCHAR(30),
    loyalty_tier VARCHAR(20),
    
    INDEX idx_segment (customer_segment),
    INDEX idx_age_group (age_group),
    INDEX idx_loyalty_tier (loyalty_tier)
);

-- ============================================================================
-- 2. CUBE FACT TABLE
-- ============================================================================

-- Sales cube fact table with multiple measures
CREATE TABLE olap_cube.fact_sales_cube (
    fact_key BIGINT AUTO_INCREMENT PRIMARY KEY,
    time_key INT NOT NULL,
    product_key INT NOT NULL,
    geography_key INT NOT NULL,
    customer_key INT NOT NULL,
    
    -- Additive measures
    sales_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    cost_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    quantity_sold INT NOT NULL DEFAULT 0,
    discount_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
    tax_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
    
    -- Semi-additive measures
    inventory_level INT DEFAULT 0,
    customer_balance DECIMAL(12,2) DEFAULT 0,
    
    -- Non-additive measures (calculated)
    profit_amount AS (sales_amount - cost_amount - discount_amount),
    profit_margin AS (
        CASE WHEN sales_amount > 0 
             THEN ((sales_amount - cost_amount - discount_amount) / sales_amount) * 100 
             ELSE 0 
        END
    ),
    
    -- Cube processing metadata
    cube_build_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Indexes for cube operations
    INDEX idx_time (time_key),
    INDEX idx_product (product_key),
    INDEX idx_geography (geography_key),
    INDEX idx_customer (customer_key),
    INDEX idx_time_product (time_key, product_key),
    INDEX idx_time_geography (time_key, geography_key),
    INDEX idx_product_geography (product_key, geography_key),
    
    -- Foreign key constraints
    FOREIGN KEY (time_key) REFERENCES olap_cube.dim_time(time_key),
    FOREIGN KEY (product_key) REFERENCES olap_cube.dim_product(product_key),
    FOREIGN KEY (geography_key) REFERENCES olap_cube.dim_geography(geography_key),
    FOREIGN KEY (customer_key) REFERENCES olap_cube.dim_customer(customer_key)
);

-- ============================================================================
-- 3. CUBE AGGREGATION TABLES (Pre-computed summaries)
-- ============================================================================

-- Time + Product aggregation
CREATE TABLE olap_cube.agg_time_product (
    time_key INT NOT NULL,
    product_key INT NOT NULL,
    total_sales_amount DECIMAL(15,2) DEFAULT 0,
    total_cost_amount DECIMAL(15,2) DEFAULT 0,
    total_quantity_sold BIGINT DEFAULT 0,
    total_profit_amount DECIMAL(15,2) DEFAULT 0,
    transaction_count BIGINT DEFAULT 0,
    avg_sale_amount DECIMAL(10,2) DEFAULT 0,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (time_key, product_key),
    INDEX idx_time (time_key),
    INDEX idx_product (product_key)
);

-- Time + Geography aggregation
CREATE TABLE olap_cube.agg_time_geography (
    time_key INT NOT NULL,
    geography_key INT NOT NULL,
    total_sales_amount DECIMAL(15,2) DEFAULT 0,
    total_cost_amount DECIMAL(15,2) DEFAULT 0,
    total_quantity_sold BIGINT DEFAULT 0,
    total_profit_amount DECIMAL(15,2) DEFAULT 0,
    transaction_count BIGINT DEFAULT 0,
    customer_count BIGINT DEFAULT 0,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (time_key, geography_key),
    INDEX idx_time (time_key),
    INDEX idx_geography (geography_key)
);

-- Product + Geography aggregation
CREATE TABLE olap_cube.agg_product_geography (
    product_key INT NOT NULL,
    geography_key INT NOT NULL,
    total_sales_amount DECIMAL(15,2) DEFAULT 0,
    total_cost_amount DECIMAL(15,2) DEFAULT 0,
    total_quantity_sold BIGINT DEFAULT 0,
    total_profit_amount DECIMAL(15,2) DEFAULT 0,
    transaction_count BIGINT DEFAULT 0,
    avg_sale_amount DECIMAL(10,2) DEFAULT 0,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (product_key, geography_key),
    INDEX idx_product (product_key),
    INDEX idx_geography (geography_key)
);

-- ============================================================================
-- 4. CUBE BUILDING PROCEDURES
-- ============================================================================

-- Procedure to build/refresh cube aggregations
DELIMITER $$
CREATE PROCEDURE olap_cube.build_cube_aggregations(
    IN p_start_date DATE,
    IN p_end_date DATE
)
BEGIN
    DECLARE v_start_time_key INT;
    DECLARE v_end_time_key INT;
    DECLARE v_error_count INT DEFAULT 0;
    
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        SET v_error_count = v_error_count + 1;
        ROLLBACK;
    END;
    
    -- Convert dates to time keys
    SET v_start_time_key = DATE_FORMAT(p_start_date, '%Y%m%d');
    SET v_end_time_key = DATE_FORMAT(p_end_date, '%Y%m%d');
    
    START TRANSACTION;
    
    -- Build Time + Product aggregation
    INSERT INTO olap_cube.agg_time_product (
        time_key, product_key, total_sales_amount, total_cost_amount,
        total_quantity_sold, total_profit_amount, transaction_count, avg_sale_amount
    )
    SELECT 
        f.time_key,
        f.product_key,
        SUM(f.sales_amount) as total_sales_amount,
        SUM(f.cost_amount) as total_cost_amount,
        SUM(f.quantity_sold) as total_quantity_sold,
        SUM(f.profit_amount) as total_profit_amount,
        COUNT(*) as transaction_count,
        AVG(f.sales_amount) as avg_sale_amount
    FROM olap_cube.fact_sales_cube f
    WHERE f.time_key BETWEEN v_start_time_key AND v_end_time_key
    GROUP BY f.time_key, f.product_key
    ON DUPLICATE KEY UPDATE
        total_sales_amount = VALUES(total_sales_amount),
        total_cost_amount = VALUES(total_cost_amount),
        total_quantity_sold = VALUES(total_quantity_sold),
        total_profit_amount = VALUES(total_profit_amount),
        transaction_count = VALUES(transaction_count),
        avg_sale_amount = VALUES(avg_sale_amount);
    
    -- Build Time + Geography aggregation
    INSERT INTO olap_cube.agg_time_geography (
        time_key, geography_key, total_sales_amount, total_cost_amount,
        total_quantity_sold, total_profit_amount, transaction_count, customer_count
    )
    SELECT 
        f.time_key,
        f.geography_key,
        SUM(f.sales_amount) as total_sales_amount,
        SUM(f.cost_amount) as total_cost_amount,
        SUM(f.quantity_sold) as total_quantity_sold,
        SUM(f.profit_amount) as total_profit_amount,
        COUNT(*) as transaction_count,
        COUNT(DISTINCT f.customer_key) as customer_count
    FROM olap_cube.fact_sales_cube f
    WHERE f.time_key BETWEEN v_start_time_key AND v_end_time_key
    GROUP BY f.time_key, f.geography_key
    ON DUPLICATE KEY UPDATE
        total_sales_amount = VALUES(total_sales_amount),
        total_cost_amount = VALUES(total_cost_amount),
        total_quantity_sold = VALUES(total_quantity_sold),
        total_profit_amount = VALUES(total_profit_amount),
        transaction_count = VALUES(transaction_count),
        customer_count = VALUES(customer_count);
    
    -- Build Product + Geography aggregation
    INSERT INTO olap_cube.agg_product_geography (
        product_key, geography_key, total_sales_amount, total_cost_amount,
        total_quantity_sold, total_profit_amount, transaction_count, avg_sale_amount
    )
    SELECT 
        f.product_key,
        f.geography_key,
        SUM(f.sales_amount) as total_sales_amount,
        SUM(f.cost_amount) as total_cost_amount,
        SUM(f.quantity_sold) as total_quantity_sold,
        SUM(f.profit_amount) as total_profit_amount,
        COUNT(*) as transaction_count,
        AVG(f.sales_amount) as avg_sale_amount
    FROM olap_cube.fact_sales_cube f
    WHERE f.time_key BETWEEN v_start_time_key AND v_end_time_key
    GROUP BY f.product_key, f.geography_key
    ON DUPLICATE KEY UPDATE
        total_sales_amount = VALUES(total_sales_amount),
        total_cost_amount = VALUES(total_cost_amount),
        total_quantity_sold = VALUES(total_quantity_sold),
        total_profit_amount = VALUES(total_profit_amount),
        transaction_count = VALUES(transaction_count),
        avg_sale_amount = VALUES(avg_sale_amount);
    
    COMMIT;
    
    SELECT 
        CASE WHEN v_error_count = 0 
             THEN 'Cube aggregations built successfully' 
             ELSE 'Error occurred during cube building' 
        END as status;
        
END$$
DELIMITER ;

-- ============================================================================
-- 5. OLAP OPERATION EXAMPLES
-- ============================================================================

-- DRILL-DOWN: From year to quarter to month
-- Start with yearly sales
SELECT 
    dt.year_number,
    SUM(f.sales_amount) as total_sales,
    SUM(f.profit_amount) as total_profit
FROM olap_cube.fact_sales_cube f
JOIN olap_cube.dim_time dt ON f.time_key = dt.time_key
GROUP BY dt.year_number
ORDER BY dt.year_number;

-- Drill down to quarterly level
SELECT 
    dt.year_number,
    dt.quarter_number,
    dt.quarter_name,
    SUM(f.sales_amount) as total_sales,
    SUM(f.profit_amount) as total_profit
FROM olap_cube.fact_sales_cube f
JOIN olap_cube.dim_time dt ON f.time_key = dt.time_key
WHERE dt.year_number = 2024
GROUP BY dt.year_number, dt.quarter_number, dt.quarter_name
ORDER BY dt.quarter_number;

-- Drill down to monthly level
SELECT 
    dt.year_number,
    dt.quarter_number,
    dt.month_number,
    dt.month_name,
    SUM(f.sales_amount) as total_sales,
    SUM(f.profit_amount) as total_profit
FROM olap_cube.fact_sales_cube f
JOIN olap_cube.dim_time dt ON f.time_key = dt.time_key
WHERE dt.year_number = 2024 AND dt.quarter_number = 1
GROUP BY dt.year_number, dt.quarter_number, dt.month_number, dt.month_name
ORDER BY dt.month_number;

-- ROLL-UP: From product to category
SELECT 
    dp.category_name,
    SUM(f.sales_amount) as total_sales,
    SUM(f.quantity_sold) as total_quantity,
    AVG(f.profit_margin) as avg_profit_margin
FROM olap_cube.fact_sales_cube f
JOIN olap_cube.dim_product dp ON f.product_key = dp.product_key
GROUP BY dp.category_name
ORDER BY total_sales DESC;

-- SLICE: Fix one dimension (specific year)
SELECT 
    dp.category_name,
    dg.region_name,
    SUM(f.sales_amount) as total_sales,
    SUM(f.profit_amount) as total_profit
FROM olap_cube.fact_sales_cube f
JOIN olap_cube.dim_time dt ON f.time_key = dt.time_key
JOIN olap_cube.dim_product dp ON f.product_key = dp.product_key
JOIN olap_cube.dim_geography dg ON f.geography_key = dg.geography_key
WHERE dt.year_number = 2024
GROUP BY dp.category_name, dg.region_name
ORDER BY total_sales DESC;

-- DICE: Filter multiple dimensions
SELECT 
    dt.month_name,
    dp.subcategory_name,
    dg.state_name,
    SUM(f.sales_amount) as total_sales,
    COUNT(*) as transaction_count
FROM olap_cube.fact_sales_cube f
JOIN olap_cube.dim_time dt ON f.time_key = dt.time_key
JOIN olap_cube.dim_product dp ON f.product_key = dp.product_key
JOIN olap_cube.dim_geography dg ON f.geography_key = dg.geography_key
WHERE dt.year_number = 2024 
  AND dt.quarter_number IN (1, 2)
  AND dp.category_name IN ('Electronics', 'Clothing')
  AND dg.region_name = 'North America'
GROUP BY dt.month_name, dp.subcategory_name, dg.state_name
ORDER BY total_sales DESC;

-- PIVOT: Rotate dimensions (months as columns)
SELECT 
    dp.category_name,
    SUM(CASE WHEN dt.month_number = 1 THEN f.sales_amount ELSE 0 END) as Jan_Sales,
    SUM(CASE WHEN dt.month_number = 2 THEN f.sales_amount ELSE 0 END) as Feb_Sales,
    SUM(CASE WHEN dt.month_number = 3 THEN f.sales_amount ELSE 0 END) as Mar_Sales,
    SUM(CASE WHEN dt.month_number = 4 THEN f.sales_amount ELSE 0 END) as Apr_Sales,
    SUM(f.sales_amount) as Total_Sales
FROM olap_cube.fact_sales_cube f
JOIN olap_cube.dim_time dt ON f.time_key = dt.time_key
JOIN olap_cube.dim_product dp ON f.product_key = dp.product_key
WHERE dt.year_number = 2024
GROUP BY dp.category_name
ORDER BY Total_Sales DESC;

-- ============================================================================
-- 6. ADVANCED CUBE ANALYTICS
-- ============================================================================

-- Moving averages using window functions
SELECT 
    dt.year_number,
    dt.month_number,
    dt.month_name,
    SUM(f.sales_amount) as monthly_sales,
    AVG(SUM(f.sales_amount)) OVER (
        ORDER BY dt.year_number, dt.month_number 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) as three_month_avg,
    LAG(SUM(f.sales_amount), 1) OVER (
        ORDER BY dt.year_number, dt.month_number
    ) as prev_month_sales,
    ((SUM(f.sales_amount) - LAG(SUM(f.sales_amount), 1) OVER (
        ORDER BY dt.year_number, dt.month_number
    )) / LAG(SUM(f.sales_amount), 1) OVER (
        ORDER BY dt.year_number, dt.month_number
    )) * 100 as month_over_month_growth
FROM olap_cube.fact_sales_cube f
JOIN olap_cube.dim_time dt ON f.time_key = dt.time_key
GROUP BY dt.year_number, dt.month_number, dt.month_name
ORDER BY dt.year_number, dt.month_number;

-- Ranking and percentiles
SELECT 
    dp.product_name,
    dp.category_name,
    SUM(f.sales_amount) as total_sales,
    RANK() OVER (PARTITION BY dp.category_name ORDER BY SUM(f.sales_amount) DESC) as category_rank,
    PERCENT_RANK() OVER (ORDER BY SUM(f.sales_amount)) as sales_percentile,
    NTILE(4) OVER (ORDER BY SUM(f.sales_amount)) as sales_quartile
FROM olap_cube.fact_sales_cube f
JOIN olap_cube.dim_product dp ON f.product_key = dp.product_key
GROUP BY dp.product_key, dp.product_name, dp.category_name
ORDER BY total_sales DESC;

-- ============================================================================
-- 7. CUBE METADATA AND MONITORING
-- ============================================================================

-- Cube metadata table
CREATE TABLE olap_cube.cube_metadata (
    cube_name VARCHAR(50) PRIMARY KEY,
    dimension_count INT NOT NULL,
    measure_count INT NOT NULL,
    fact_table_name VARCHAR(100) NOT NULL,
    total_records BIGINT DEFAULT 0,
    last_build_date TIMESTAMP,
    build_duration_seconds INT,
    cube_size_mb DECIMAL(10,2),
    is_active BOOLEAN DEFAULT TRUE,
    
    INDEX idx_last_build (last_build_date)
);

-- Cube usage statistics
CREATE TABLE olap_cube.cube_usage_stats (
    usage_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    cube_name VARCHAR(50) NOT NULL,
    query_type VARCHAR(20) NOT NULL, -- 'DRILL_DOWN', 'ROLL_UP', 'SLICE', 'DICE', 'PIVOT'
    dimensions_used TEXT,
    measures_used TEXT,
    query_duration_ms INT,
    rows_returned BIGINT,
    query_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    user_session VARCHAR(100),
    
    INDEX idx_cube_name (cube_name),
    INDEX idx_query_timestamp (query_timestamp),
    INDEX idx_query_type (query_type)
);

-- Procedure to update cube metadata
DELIMITER $
CREATE PROCEDURE olap_cube.update_cube_metadata(
    IN p_cube_name VARCHAR(50)
)
BEGIN
    DECLARE v_record_count BIGINT;
    DECLARE v_table_size_mb DECIMAL(10,2);
    
    -- Get fact table record count
    SELECT COUNT(*) INTO v_record_count
    FROM olap_cube.fact_sales_cube;
    
    -- Get table size (approximate)
    SELECT 
        ROUND(((data_length + index_length) / 1024 / 1024), 2) INTO v_table_size_mb
    FROM information_schema.TABLES 
    WHERE table_schema = 'olap_cube' 
      AND table_name = 'fact_sales_cube';
    
    -- Update metadata
    INSERT INTO olap_cube.cube_metadata (
        cube_name, dimension_count, measure_count, fact_table_name,
        total_records, last_build_date, cube_size_mb
    ) VALUES (
        p_cube_name, 4, 8, 'fact_sales_cube',
        v_record_count, NOW(), v_table_size_mb
    )
    ON DUPLICATE KEY UPDATE
        total_records = v_record_count,
        last_build_date = NOW(),
        cube_size_mb = v_table_size_mb;
        
END$
DELIMITER ;

-- ============================================================================
-- 8. CUBE PERFORMANCE OPTIMIZATION
-- ============================================================================

-- Create materialized view for frequently accessed aggregations
CREATE TABLE olap_cube.mv_monthly_product_sales AS
SELECT 
    dt.year_number,
    dt.month_number,
    dt.month_name,
    dp.product_key,
    dp.product_name,
    dp.category_name,
    SUM(f.sales_amount) as total_sales,
    SUM(f.cost_amount) as total_cost,
    SUM(f.quantity_sold) as total_quantity,
    SUM(f.profit_amount) as total_profit,
    COUNT(*) as transaction_count,
    AVG(f.sales_amount) as avg_sale_amount
FROM olap_cube.fact_sales_cube f
JOIN olap_cube.dim_time dt ON f.time_key = dt.time_key
JOIN olap_cube.dim_product dp ON f.product_key = dp.product_key
GROUP BY dt.year_number, dt.month_number, dt.month_name,
         dp.product_key, dp.product_name, dp.category_name;

-- Add indexes to materialized view
ALTER TABLE olap_cube.mv_monthly_product_sales
ADD INDEX idx_year_month (year_number, month_number),
ADD INDEX idx_category (category_name),
ADD INDEX idx_product (product_key);

-- Procedure to refresh materialized views
DELIMITER $
CREATE PROCEDURE olap_cube.refresh_materialized_views()
BEGIN
    DECLARE v_start_time TIMESTAMP DEFAULT NOW();
    DECLARE v_end_time TIMESTAMP;
    
    -- Refresh monthly product sales view
    TRUNCATE TABLE olap_cube.mv_monthly_product_sales;
    
    INSERT INTO olap_cube.mv_monthly_product_sales
    SELECT 
        dt.year_number,
        dt.month_number,
        dt.month_name,
        dp.product_key,
        dp.product_name,
        dp.category_name,
        SUM(f.sales_amount) as total_sales,
        SUM(f.cost_amount) as total_cost,
        SUM(f.quantity_sold) as total_quantity,
        SUM(f.profit_amount) as total_profit,
        COUNT(*) as transaction_count,
        AVG(f.sales_amount) as avg_sale_amount
    FROM olap_cube.fact_sales_cube f
    JOIN olap_cube.dim_time dt ON f.time_key = dt.time_key
    JOIN olap_cube.dim_product dp ON f.product_key = dp.product_key
    GROUP BY dt.year_number, dt.month_number, dt.month_name,
             dp.product_key, dp.product_name, dp.category_name;
    
    SET v_end_time = NOW();
    
    -- Log refresh activity
    INSERT INTO olap_cube.cube_usage_stats (
        cube_name, query_type, query_duration_ms, rows_returned
    ) VALUES (
        'sales_cube', 'REFRESH_MV', 
        TIMESTAMPDIFF(MICROSECOND, v_start_time, v_end_time) / 1000,
        ROW_COUNT()
    );
    
END$
DELIMITER ;

-- ============================================================================
-- 9. CUBE SECURITY AND ACCESS CONTROL
-- ============================================================================

-- Create roles for different access levels
-- CREATE ROLE cube_reader;
-- CREATE ROLE cube_analyst;
-- CREATE ROLE cube_admin;

-- Grant appropriate permissions
-- GRANT SELECT ON olap_cube.* TO cube_reader;
-- GRANT SELECT, INSERT, UPDATE ON olap_cube.agg_* TO cube_analyst;
-- GRANT ALL PRIVILEGES ON olap_cube.* TO cube_admin;

-- Row-level security example (using views)
CREATE VIEW olap_cube.vw_regional_sales AS
SELECT 
    f.*,
    dt.year_number,
    dt.month_name,
    dp.category_name,
    dg.region_name
FROM olap_cube.fact_sales_cube f
JOIN olap_cube.dim_time dt ON f.time_key = dt.time_key
JOIN olap_cube.dim_product dp ON f.product_key = dp.product_key
JOIN olap_cube.dim_geography dg ON f.geography_key = dg.geography_key
WHERE dg.region_name = USER(); -- Assuming username matches region

-- ============================================================================
-- 10. CUBE SAMPLE DATA GENERATION
-- ============================================================================

-- Procedure to generate sample cube data for testing
DELIMITER $
CREATE PROCEDURE olap_cube.generate_sample_data(
    IN p_record_count INT
)
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE v_time_key INT;
    DECLARE v_product_key INT;
    DECLARE v_geography_key INT;
    DECLARE v_customer_key INT;
    
    WHILE i <= p_record_count DO
        -- Generate random keys
        SET v_time_key = 20240000 + FLOOR(RAND() * 365) + 101;
        SET v_product_key = FLOOR(RAND() * 100) + 1;
        SET v_geography_key = FLOOR(RAND() * 50) + 1;
        SET v_customer_key = FLOOR(RAND() * 1000) + 1;
        
        INSERT INTO olap_cube.fact_sales_cube (
            time_key, product_key, geography_key, customer_key,
            sales_amount, cost_amount, quantity_sold, discount_amount
        ) VALUES (
            v_time_key,
            v_product_key,
            v_geography_key,
            v_customer_key,
            ROUND(RAND() * 1000 + 10, 2),
            ROUND(RAND() * 500 + 5, 2),
            FLOOR(RAND() * 10) + 1,
            ROUND(RAND() * 50, 2)
        );
        
        SET i = i + 1;
    END WHILE;
    
    SELECT CONCAT('Generated ', p_record_count, ' sample records') as result;
END$
DELIMITER ;

-- ============================================================================
-- OLAP CUBE BEST PRACTICES:
-- 1. Design dimensions with proper hierarchies for drill-down/roll-up
-- 2. Pre-compute frequently accessed aggregations
-- 3. Use appropriate indexing strategies for cube operations
-- 4. Implement incremental cube processing for large datasets
-- 5. Monitor cube usage patterns and optimize accordingly
-- 6. Maintain cube metadata and lineage information
-- 7. Implement proper security and access controls
-- 8. Consider partitioning strategies for very large cubes
-- 9. Use materialized views for complex, frequently-used queries
-- 10. Regular maintenance and optimization of cube structures
-- ============================================================================

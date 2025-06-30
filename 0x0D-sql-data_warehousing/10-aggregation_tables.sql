-- =====================================================
-- File: 10-aggregation_tables.sql
-- Description: Pre-aggregated tables for improved query performance
-- Author: Alpha0-1
-- =====================================================

-- Aggregation tables (also called summary tables or OLAP cubes)
-- store pre-calculated results to improve query performance
-- This file demonstrates various aggregation patterns and strategies

-- =====================================================
-- BASIC AGGREGATION TABLES
-- =====================================================

-- Daily sales summary
CREATE TABLE agg_daily_sales (
    date_key INT,
    sale_date DATE,
    total_orders INT,
    total_revenue DECIMAL(15,2),
    total_customers INT,
    avg_order_value DECIMAL(10,2),
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (date_key),
    INDEX idx_sale_date (sale_date)
);

-- Monthly sales summary by customer segment
CREATE TABLE agg_monthly_customer_sales (
    year_month VARCHAR(7), -- Format: YYYY-MM
    customer_segment VARCHAR(50),
    customer_count INT,
    total_orders INT,
    total_revenue DECIMAL(15,2),
    avg_orders_per_customer DECIMAL(8,2),
    avg_revenue_per_customer DECIMAL(10,2),
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (year_month, customer_segment),
    INDEX idx_year_month (year_month)
);

-- Product performance summary
CREATE TABLE agg_product_performance (
    product_key INT,
    product_name VARCHAR(200),
    category VARCHAR(100),
    total_quantity_sold INT,
    total_revenue DECIMAL(15,2),
    total_orders INT,
    avg_price DECIMAL(10,2),
    first_sale_date DATE,
    last_sale_date DATE,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (product_key),
    INDEX idx_category (category),
    INDEX idx_revenue_desc (total_revenue DESC)
);

-- =====================================================
-- HIERARCHICAL AGGREGATIONS
-- =====================================================

-- Geographic sales hierarchy: Country -> State -> City
CREATE TABLE agg_geographic_sales (
    geo_level VARCHAR(20), -- COUNTRY, STATE, CITY
    country VARCHAR(100),
    state VARCHAR(100),
    city VARCHAR(100),
    time_period VARCHAR(10), -- YEAR, QUARTER, MONTH
    period_value VARCHAR(7), -- YYYY, YYYY-Q1, YYYY-MM
    total_orders INT,
    total_revenue DECIMAL(15,2),
    total_customers INT,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_geo_hierarchy (geo_level, country, state, city),
    INDEX idx_time_period (time_period, period_value)
);

-- Time-based aggregation hierarchy
CREATE TABLE agg_time_hierarchy_sales (
    time_level VARCHAR(20), -- YEAR, QUARTER, MONTH, WEEK, DAY
    year_value INT,
    quarter_value INT,
    month_value INT,
    week_value INT,
    date_value DATE,
    total_orders INT,
    total_revenue DECIMAL(15,2),
    unique_customers INT,
    avg_order_value DECIMAL(10,2),
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_time_level (time_level, year_value, quarter_value, month_value),
    INDEX idx_date_value (date_value)
);

-- =====================================================
-- CUBE AND ROLLUP AGGREGATIONS
-- =====================================================

-- Multi-dimensional sales cube
CREATE TABLE agg_sales_cube (
    -- Dimension keys (NULL for rollup levels)
    customer_segment VARCHAR(50),
    product_category VARCHAR(100),
    geographic_region VARCHAR(100),
    time_period VARCHAR(7), -- YYYY-MM
    
    -- Measures
    total_orders INT,
    total_revenue DECIMAL(15,2),
    total_quantity INT,
    unique_customers INT,
    avg_order_value DECIMAL(10,2),
    
    -- Metadata
    aggregation_level VARCHAR(100), -- Describes which dimensions are aggregated
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_cube_dimensions (customer_segment, product_category, geographic_region, time_period),
    INDEX idx_aggregation_level (aggregation_level)
);

-- =====================================================
-- INCREMENTAL AGGREGATION PROCEDURES
-- =====================================================

-- Procedure to refresh daily sales aggregation
CREATE OR REPLACE PROCEDURE refresh_daily_sales_agg(IN target_date DATE)
BEGIN
    
    -- Delete existing data for the target date
    DELETE FROM agg_daily_sales WHERE sale_date = target_date;
    
    -- Insert fresh aggregated data
    INSERT INTO agg_daily_sales (
        date_key,
        sale_date,
        total_orders,
        total_revenue,
        total_customers,
        avg_order_value
    )
    SELECT 
        dd.date_key,
        dd.full_date,
        COUNT(fo.order_key) as total_orders,
        SUM(fo.order_amount) as total_revenue,
        COUNT(DISTINCT fo.customer_key) as total_customers,
        AVG(fo.order_amount) as avg_order_value
    FROM dim_date dd
    LEFT JOIN fact_orders fo ON dd.date_key = fo.date_key
    WHERE dd.full_date = target_date
    GROUP BY dd.date_key, dd.full_date;
    
    -- Log the refresh
    INSERT INTO etl_log (job_name, table_name, load_date, records_processed, status)
    VALUES ('refresh_daily_sales_agg', 'agg_daily_sales', target_date, ROW_COUNT(), 'SUCCESS');
    
END;

-- Procedure to refresh monthly customer aggregation
CREATE OR REPLACE PROCEDURE refresh_monthly_customer_agg(IN target_year_month VARCHAR(7))
BEGIN
    
    DECLARE start_date DATE;
    DECLARE end_date DATE;
    
    -- Calculate date range for the month
    SET start_date = STR_TO_DATE(CONCAT(target_year_month, '-01'), '%Y-%m-%d');
    SET end_date = LAST_DAY(start_date);
    
    -- Delete existing data for the target month
    DELETE FROM agg_monthly_customer_sales WHERE year_month = target_year_month;
    
    -- Insert fresh aggregated data
    INSERT INTO agg_monthly_customer_sales (
        year_month,
        customer_segment,
        customer_count,
        total_orders,
        total_revenue,
        avg_orders_per_customer,
        avg_revenue_per_customer
    )
    SELECT 
        target_year_month,
        dc.customer_segment,
        COUNT(DISTINCT dc.customer_key) as customer_count,
        COUNT(fo.order_key) as total_orders,
        SUM(fo.order_amount) as total_revenue,
        COUNT(fo.order_key) / COUNT(DISTINCT dc.customer_key) as avg_orders_per_customer,
        SUM(fo.order_amount) / COUNT(DISTINCT dc.customer_key) as avg_revenue_per_customer
    FROM fact_orders fo
    JOIN dim_customer dc ON fo.customer_key = dc.customer_key
    JOIN dim_date dd ON fo.date_key = dd.date_key
    WHERE dd.full_date BETWEEN start_date AND end_date
    AND dc.is_current = 'Y'
    GROUP BY dc.customer_segment;
    
END;

-- =====================================================
-- ADVANCED AGGREGATION PATTERNS
-- =====================================================

-- Moving averages aggregation
CREATE TABLE agg_moving_averages (
    date_key INT,
    sale_date DATE,
    daily_revenue DECIMAL(15,2),
    ma_7_day DECIMAL(15,2),  -- 7-day moving average
    ma_30_day DECIMAL(15,2), -- 30-day moving average
    ma_90_day DECIMAL(15,2), -- 90-day moving average
    revenue_trend VARCHAR(20), -- UP, DOWN, STABLE
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (date_key),
    INDEX idx_sale_date (sale_date)
);

-- Procedure to calculate moving averages
CREATE OR REPLACE PROCEDURE calculate_moving_averages()
BEGIN
    
    TRUNCATE TABLE agg_moving_averages;
    
    INSERT INTO agg_moving_averages (
        date_key,
        sale_date,
        daily_revenue,
        ma_7_day,
        ma_30_day,
        ma_90_day,
        revenue_trend
    )
    SELECT 
        ads.date_key,
        ads.sale_date,
        ads.total_revenue as daily_revenue,
        
        -- 7-day moving average
        AVG(ads2.total_revenue) OVER (
            ORDER BY ads.sale_date 
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ) as ma_7_day,
        
        -- 30-day moving average
        AVG(ads3.total_revenue) OVER (
            ORDER BY ads.sale_date 
            ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
        ) as ma_30_day,
        
        -- 90-day moving average
        AVG(ads4.total_revenue) OVER (
            ORDER BY ads.sale_date 
            ROWS BETWEEN 89 PRECEDING AND CURRENT ROW
        ) as ma_90_day,
        
        -- Trend calculation
        CASE 
            WHEN ads.total_revenue > LAG(ads.total_revenue, 7) OVER (ORDER BY ads.sale_date) * 1.05 THEN 'UP'
            WHEN ads.total_revenue < LAG(ads.total_revenue, 7) OVER (ORDER BY ads.sale_date) * 0.95 THEN 'DOWN'
            ELSE 'STABLE'
        END as revenue_trend
        
    FROM agg_daily_sales ads
    LEFT JOIN agg_daily_sales ads2 ON ads2.sale_date BETWEEN ads.sale_date - INTERVAL 6 DAY AND ads.sale_date
    LEFT JOIN agg_daily_sales ads3 ON ads3.sale_date BETWEEN ads.sale_date - INTERVAL 29 DAY AND ads.sale_date
    LEFT JOIN agg_daily_sales ads4 ON ads4.sale_date BETWEEN ads.sale_date - INTERVAL 89 DAY AND ads.sale_date
    ORDER BY ads.sale_date;
    
END;

-- Cohort analysis aggregation
CREATE TABLE agg_customer_cohorts (
    cohort_month VARCHAR(7), -- Registration month
    period_number INT, -- Months since registration
    customers_in_cohort INT,
    active_customers INT,
    retention_rate DECIMAL(5,2),
    total_revenue DECIMAL(15,2),
    avg_revenue_per_customer DECIMAL(10,2),
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (cohort_month, period_number),
    INDEX idx_cohort_month (cohort_month)
);

-- =====================================================
-- MATERIALIZED VIEW ALTERNATIVE
-- =====================================================

-- For databases that support materialized views
-- This is an example of how aggregations can be implemented as materialized views

CREATE MATERIALIZED VIEW mv_quarterly_sales_summary AS
SELECT 
    YEAR(dd.full_date) as year_value,
    QUARTER(dd.full_date) as quarter_value,
    CONCAT(YEAR(dd.full_date), '-Q', QUARTER(dd.full_date)) as year_quarter,
    COUNT(fo.order_key) as total_orders,
    SUM(fo.order_amount) as total_revenue,
    COUNT(DISTINCT fo.customer_key) as unique_customers,
    AVG(fo.order_amount) as avg_order_value,
    MIN(fo.order_amount) as min_order_value,
    MAX(fo.order_amount) as max_order_value
FROM fact_orders fo
JOIN dim_date dd ON fo.date_key = dd.date_key
GROUP BY 
    YEAR(dd.full_date),
    QUARTER(dd.full_date)
ORDER BY year_value, quarter_value;

-- =====================================================
-- AGGREGATION REFRESH STRATEGIES
-- =====================================================

-- Full refresh strategy (rebuild entire aggregation)
CREATE OR REPLACE PROCEDURE full_refresh_aggregations()
BEGIN
    
    -- Refresh daily sales (last 90 days)
    DECLARE finished INT DEFAULT FALSE;
    DECLARE refresh_date DATE;
    DECLARE date_cursor CURSOR FOR
        SELECT DISTINCT sale_date 
        FROM agg_daily_sales 
        WHERE sale_date >= CURRENT_DATE - INTERVAL 90 DAY;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET finished = TRUE;
    
    OPEN date_cursor;
    refresh_loop: LOOP
        FETCH date_cursor INTO refresh_date;
        IF finished THEN
            LEAVE refresh_loop;
        END IF;
        
        CALL refresh_daily_sales_agg(refresh_date);
    END LOOP;
    CLOSE date_cursor;
    
    -- Refresh monthly aggregations
    CALL refresh_monthly_customer_agg(DATE_FORMAT(CURRENT_DATE, '%Y-%m'));
    
    -- Refresh product performance
    CALL refresh_product_performance_agg();
    
    -- Calculate moving averages
    CALL calculate_moving_averages();
    
END;

-- Smart incremental refresh (only refresh changed data)
CREATE OR REPLACE PROCEDURE incremental_refresh_aggregations()
BEGIN
    
    DECLARE last_refresh_date DATE;
    
    -- Get last successful refresh date
    SELECT MAX(load_date) INTO last_refresh_date
    FROM etl_log 
    WHERE job_name = 'incremental_aggregation_refresh' 
    AND status = 'SUCCESS';
    
    -- Default to yesterday if no previous refresh
    IF last_refresh_date IS NULL THEN
        SET last_refresh_date = CURRENT_DATE - 1;
    END IF;
    
    -- Refresh only affected periods
    -- This would include dates that had new or updated fact data
    INSERT INTO agg_daily_sales (date_key, sale_date, total_orders, total_revenue, total_customers, avg_order_value)
    SELECT 
        dd.date_key,
        dd.full_date,
        COUNT(fo.order_key),
        SUM(fo.order_amount),
        COUNT(DISTINCT fo.customer_key),
        AVG(fo.order_amount)
    FROM dim_date dd
    LEFT JOIN fact_orders fo ON dd.date_key = fo.date_key
    WHERE dd.full_date > last_refresh_date
    AND dd.full_date <= CURRENT_DATE
    GROUP BY dd.date_key, dd.full_date
    ON DUPLICATE KEY UPDATE
        total_orders = VALUES(total_orders),
        total_revenue = VALUES(total_revenue),
        total_customers = VALUES(total_customers),
        avg_order_value = VALUES(avg_order_value),
        updated_date = CURRENT_TIMESTAMP;
    
    -- Log successful refresh
    INSERT INTO etl_log (job_name, table_name, load_date, status)
    VALUES ('incremental_aggregation_refresh', 'agg_daily_sales', CURRENT_DATE, 'SUCCESS');
    
END;

-- =====================================================
-- AGGREGATION VALIDATION PROCEDURES
-- =====================================================

-- Validate aggregation accuracy
CREATE OR REPLACE PROCEDURE validate_aggregations(IN validation_date DATE)
BEGIN
    
    DECLARE agg_total_revenue DECIMAL(15,2);
    DECLARE fact_total_revenue DECIMAL(15,2);
    DECLARE variance_pct DECIMAL(5,2);
    
    -- Get aggregated total
    SELECT total_revenue INTO agg_total_revenue
    FROM agg_daily_sales 
    WHERE sale_date = validation_date;
    
    -- Get fact table total
    SELECT SUM(fo.order_amount) INTO fact_total_revenue
    FROM fact_orders fo
    JOIN dim_date dd ON fo.date_key = dd.date_key
    WHERE dd.full_date = validation_date;
    
    -- Calculate variance
    SET variance_pct = ABS(agg_total_revenue - fact_total_revenue) / fact_total_revenue * 100;
    
    -- Log validation result
    INSERT INTO etl_log (
        job_name, 
        table_name, 
        load_date, 
        status, 
        error_message
    )
    VALUES (
        'aggregation_validation',
        'agg_daily_sales',
        validation_date,
        CASE WHEN variance_pct < 0.01 THEN 'PASS' ELSE 'FAIL' END,
        CONCAT('Variance: ', variance_pct, '% (Agg: ', agg_total_revenue, ', Fact: ', fact_total_revenue, ')')
    );
    
END;

-- =====================================================
-- USAGE EXAMPLES AND QUERIES
-- =====================================================

-- Example queries using aggregated tables:

-- 1. Get daily sales trend for last 30 days
-- SELECT sale_date, total_revenue, total_orders
-- FROM agg_daily_sales 
-- WHERE sale_date >= CURRENT_DATE - INTERVAL 30 DAY
-- ORDER BY sale_date;

-- 2. Compare monthly performance by customer segment
-- SELECT customer_segment, total_revenue, customer_count
-- FROM agg_monthly_customer_sales 
-- WHERE year_month = '2025-06'
-- ORDER BY total_revenue DESC;

-- 3. Get moving averages with trend
-- SELECT sale_date, daily_revenue, ma_7_day, ma_30_day, revenue_trend
-- FROM agg_moving_averages 
-- WHERE sale_date >= CURRENT_DATE - INTERVAL 90 DAY
-- ORDER BY sale_date;

-- 4. Drill down from country to city level
-- SELECT country, state, city, total_revenue
-- FROM agg_geographic_sales 
-- WHERE geo_level = 'CITY' 
-- AND time_period = 'MONTH' 
-- AND period_value = '2025-06'
-- ORDER BY total_revenue DESC;

-- =====================================================
-- AGGREGATION MAINTENANCE SCHEDULE
-- =====================================================

-- Recommended refresh schedule:
-- Daily aggregations: Every night after fact table loads
-- Weekly aggregations: Every Sunday night
-- Monthly aggregations: First day of each month
-- Quarterly aggregations: First day of each quarter

-- Example scheduling with cron-like syntax:
-- Daily: CALL incremental_refresh_aggregations(); -- Run at 2 AM daily
-- Weekly: CALL refresh_weekly_aggregations(); -- Run at 3 AM on Sundays
-- Monthly: CALL refresh_monthly_aggregations(); -- Run at 4 AM on 1st of month

-- =====================================================
-- PERFORMANCE OPTIMIZATION TIPS
-- =====================================================

/*
1. INDEXING STRATEGY:
   - Create indexes on commonly filtered columns
   - Use composite indexes for multi-column filters
   - Consider covering indexes for frequently accessed columns

2. PARTITIONING:
   - Partition large aggregation tables by date
   - Use range partitioning for time-based data
   - Consider hash partitioning for evenly distributed data

3. COMPRESSION:
   - Use table compression for large aggregation tables
   - Consider columnar storage for analytical workloads
   - Archive old aggregation data to separate storage

4. REFRESH OPTIMIZATION:
   - Use incremental refresh when possible
   - Implement parallel processing for independent aggregations
   - Schedule refreshes during low-usage periods
   - Monitor and tune refresh performance regularly

5. QUERY OPTIMIZATION:
   - Design aggregation tables to match common query patterns
   - Pre-calculate commonly requested metrics
   - Use appropriate data types to minimize storage
   - Consider denormalization for frequently joined data
*/

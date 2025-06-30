-- ============================================================================
-- File: 6-data_marts.sql
-- Description: Data Mart Creation and Management
-- Author: Alpha0-1
-- Objective: Creating subject-oriented data marts from enterprise data warehouse
-- ============================================================================

-- Data marts are subset of data warehouse focused on specific business area
-- They provide faster query performance and easier data access for departments

-- ============================================================================
-- SCENARIO: E-commerce company creating department-specific data marts
-- ============================================================================

-- Create schema for data marts
CREATE SCHEMA IF NOT EXISTS sales_mart;
CREATE SCHEMA IF NOT EXISTS marketing_mart;
CREATE SCHEMA IF NOT EXISTS finance_mart;

-- ============================================================================
-- 1. SALES DATA MART
-- ============================================================================

-- Sales fact table for sales department
CREATE TABLE sales_mart.fact_sales (
    sale_id INT PRIMARY KEY,
    date_key INT NOT NULL,
    product_key INT NOT NULL,
    customer_key INT NOT NULL,
    store_key INT NOT NULL,
    sales_amount DECIMAL(10,2) NOT NULL,
    quantity_sold INT NOT NULL,
    discount_amount DECIMAL(8,2) DEFAULT 0,
    cost_amount DECIMAL(10,2) NOT NULL,
    profit_amount AS (sales_amount - cost_amount - discount_amount),
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Indexes for performance
    INDEX idx_date_key (date_key),
    INDEX idx_product_key (product_key),
    INDEX idx_customer_key (customer_key)
);

-- Product dimension for sales mart (denormalized)
CREATE TABLE sales_mart.dim_product (
    product_key INT PRIMARY KEY,
    product_id VARCHAR(20) NOT NULL,
    product_name VARCHAR(100) NOT NULL,
    category_name VARCHAR(50) NOT NULL,
    subcategory_name VARCHAR(50),
    brand_name VARCHAR(50),
    unit_price DECIMAL(8,2) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_category (category_name),
    INDEX idx_brand (brand_name)
);

-- Customer dimension for sales mart
CREATE TABLE sales_mart.dim_customer (
    customer_key INT PRIMARY KEY,
    customer_id VARCHAR(20) NOT NULL,
    customer_name VARCHAR(100) NOT NULL,
    customer_segment VARCHAR(20) NOT NULL,
    city VARCHAR(50),
    state VARCHAR(50),
    country VARCHAR(50),
    registration_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    
    INDEX idx_segment (customer_segment),
    INDEX idx_location (city, state, country)
);

-- ============================================================================
-- 2. MARKETING DATA MART
-- ============================================================================

-- Campaign performance fact table
CREATE TABLE marketing_mart.fact_campaign_performance (
    campaign_key INT PRIMARY KEY,
    date_key INT NOT NULL,
    channel_key INT NOT NULL,
    campaign_id VARCHAR(20) NOT NULL,
    impressions INT DEFAULT 0,
    clicks INT DEFAULT 0,
    conversions INT DEFAULT 0,
    cost_amount DECIMAL(10,2) DEFAULT 0,
    revenue_amount DECIMAL(10,2) DEFAULT 0,
    click_through_rate AS (CASE WHEN impressions > 0 THEN clicks/impressions ELSE 0 END),
    conversion_rate AS (CASE WHEN clicks > 0 THEN conversions/clicks ELSE 0 END),
    return_on_ad_spend AS (CASE WHEN cost_amount > 0 THEN revenue_amount/cost_amount ELSE 0 END),
    
    INDEX idx_date_key (date_key),
    INDEX idx_channel_key (channel_key),
    INDEX idx_campaign_id (campaign_id)
);

-- Marketing channel dimension
CREATE TABLE marketing_mart.dim_marketing_channel (
    channel_key INT PRIMARY KEY,
    channel_id VARCHAR(20) NOT NULL,
    channel_name VARCHAR(50) NOT NULL,
    channel_type VARCHAR(30) NOT NULL, -- 'Digital', 'Traditional', 'Social'
    channel_cost_model VARCHAR(20) NOT NULL, -- 'CPC', 'CPM', 'Fixed'
    is_active BOOLEAN DEFAULT TRUE,
    
    INDEX idx_channel_type (channel_type)
);

-- ============================================================================
-- 3. FINANCE DATA MART
-- ============================================================================

-- Financial metrics fact table
CREATE TABLE finance_mart.fact_financial_metrics (
    metric_key INT PRIMARY KEY,
    date_key INT NOT NULL,
    account_key INT NOT NULL,
    department_key INT NOT NULL,
    revenue_amount DECIMAL(12,2) DEFAULT 0,
    expense_amount DECIMAL(12,2) DEFAULT 0,
    profit_amount AS (revenue_amount - expense_amount),
    budget_amount DECIMAL(12,2) DEFAULT 0,
    variance_amount AS (revenue_amount - budget_amount),
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_date_key (date_key),
    INDEX idx_account_key (account_key),
    INDEX idx_department_key (department_key)
);

-- Chart of accounts dimension
CREATE TABLE finance_mart.dim_account (
    account_key INT PRIMARY KEY,
    account_code VARCHAR(20) NOT NULL,
    account_name VARCHAR(100) NOT NULL,
    account_type VARCHAR(20) NOT NULL, -- 'Asset', 'Liability', 'Equity', 'Revenue', 'Expense'
    account_category VARCHAR(50),
    parent_account_code VARCHAR(20),
    is_active BOOLEAN DEFAULT TRUE,
    
    INDEX idx_account_type (account_type),
    INDEX idx_account_category (account_category)
);

-- ============================================================================
-- 4. DATA MART POPULATION PROCEDURES
-- ============================================================================

-- Procedure to populate sales data mart from main warehouse
DELIMITER $$
CREATE PROCEDURE sales_mart.populate_sales_mart(
    IN p_start_date DATE,
    IN p_end_date DATE
)
BEGIN
    DECLARE v_error_count INT DEFAULT 0;
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        SET v_error_count = v_error_count + 1;
        ROLLBACK;
    END;
    
    START TRANSACTION;
    
    -- Clear existing data for the date range
    DELETE FROM sales_mart.fact_sales 
    WHERE date_key BETWEEN DATE_FORMAT(p_start_date, '%Y%m%d') 
                     AND DATE_FORMAT(p_end_date, '%Y%m%d');
    
    -- Insert sales data from main warehouse
    INSERT INTO sales_mart.fact_sales (
        sale_id, date_key, product_key, customer_key, store_key,
        sales_amount, quantity_sold, discount_amount, cost_amount
    )
    SELECT 
        s.sale_id,
        DATE_FORMAT(s.sale_date, '%Y%m%d') as date_key,
        p.product_key,
        c.customer_key,
        st.store_key,
        s.sales_amount,
        s.quantity_sold,
        s.discount_amount,
        s.cost_amount
    FROM main_warehouse.fact_sales s
    JOIN main_warehouse.dim_product p ON s.product_id = p.product_id
    JOIN main_warehouse.dim_customer c ON s.customer_id = c.customer_id
    JOIN main_warehouse.dim_store st ON s.store_id = st.store_id
    WHERE s.sale_date BETWEEN p_start_date AND p_end_date;
    
    -- Update mart metadata
    INSERT INTO sales_mart.mart_refresh_log (
        mart_name, refresh_date, records_processed, status
    ) VALUES (
        'sales_mart', NOW(), ROW_COUNT(), 'SUCCESS'
    );
    
    COMMIT;
    
    -- Return status
    SELECT 
        CASE WHEN v_error_count = 0 
             THEN 'Sales mart populated successfully' 
             ELSE 'Error occurred during population' 
        END as status;
        
END$$
DELIMITER ;

-- ============================================================================
-- 5. DATA MART REFRESH AUTOMATION
-- ============================================================================

-- Create refresh log table
CREATE TABLE IF NOT EXISTS sales_mart.mart_refresh_log (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    mart_name VARCHAR(50) NOT NULL,
    refresh_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    records_processed INT DEFAULT 0,
    status VARCHAR(20) DEFAULT 'PENDING',
    error_message TEXT,
    
    INDEX idx_mart_name (mart_name),
    INDEX idx_refresh_date (refresh_date)
);

-- Function to check data mart freshness
DELIMITER $$
CREATE FUNCTION sales_mart.check_mart_freshness(
    p_mart_name VARCHAR(50)
) RETURNS VARCHAR(20)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_last_refresh TIMESTAMP;
    DECLARE v_hours_old INT;
    
    SELECT MAX(refresh_date) INTO v_last_refresh
    FROM sales_mart.mart_refresh_log
    WHERE mart_name = p_mart_name AND status = 'SUCCESS';
    
    SET v_hours_old = TIMESTAMPDIFF(HOUR, v_last_refresh, NOW());
    
    RETURN CASE 
        WHEN v_hours_old <= 2 THEN 'FRESH'
        WHEN v_hours_old <= 8 THEN 'STALE'
        ELSE 'EXPIRED'
    END;
END$$
DELIMITER ;

-- ============================================================================
-- 6. DATA MART USAGE EXAMPLES
-- ============================================================================

-- Example 1: Sales performance by product category
SELECT 
    dp.category_name,
    COUNT(fs.sale_id) as total_sales,
    SUM(fs.sales_amount) as total_revenue,
    AVG(fs.sales_amount) as avg_sale_amount,
    SUM(fs.profit_amount) as total_profit
FROM sales_mart.fact_sales fs
JOIN sales_mart.dim_product dp ON fs.product_key = dp.product_key
WHERE fs.date_key >= DATE_FORMAT(CURDATE() - INTERVAL 30 DAY, '%Y%m%d')
GROUP BY dp.category_name
ORDER BY total_revenue DESC;

-- Example 2: Customer segment analysis
SELECT 
    dc.customer_segment,
    COUNT(DISTINCT fs.customer_key) as unique_customers,
    COUNT(fs.sale_id) as total_transactions,
    SUM(fs.sales_amount) as total_revenue,
    AVG(fs.sales_amount) as avg_transaction_value
FROM sales_mart.fact_sales fs
JOIN sales_mart.dim_customer dc ON fs.customer_key = dc.customer_key
GROUP BY dc.customer_segment
ORDER BY total_revenue DESC;

-- Example 3: Marketing campaign ROI analysis
SELECT 
    dmc.channel_name,
    SUM(fcp.cost_amount) as total_spend,
    SUM(fcp.revenue_amount) as total_revenue,
    AVG(fcp.return_on_ad_spend) as avg_roas,
    SUM(fcp.conversions) as total_conversions
FROM marketing_mart.fact_campaign_performance fcp
JOIN marketing_mart.dim_marketing_channel dmc ON fcp.channel_key = dmc.channel_key
WHERE fcp.date_key >= DATE_FORMAT(CURDATE() - INTERVAL 90 DAY, '%Y%m%d')
GROUP BY dmc.channel_name
HAVING total_spend > 0
ORDER BY avg_roas DESC;

-- ============================================================================
-- 7. DATA MART MAINTENANCE
-- ============================================================================

-- Procedure to archive old data mart data
DELIMITER $$
CREATE PROCEDURE sales_mart.archive_old_data(
    IN p_retention_days INT
)
BEGIN
    DECLARE v_cutoff_date DATE;
    DECLARE v_archived_count INT DEFAULT 0;
    
    SET v_cutoff_date = CURDATE() - INTERVAL p_retention_days DAY;
    
    -- Archive to historical table
    INSERT INTO sales_mart.fact_sales_archive
    SELECT * FROM sales_mart.fact_sales
    WHERE date_key < DATE_FORMAT(v_cutoff_date, '%Y%m%d');
    
    SET v_archived_count = ROW_COUNT();
    
    -- Delete from active table
    DELETE FROM sales_mart.fact_sales
    WHERE date_key < DATE_FORMAT(v_cutoff_date, '%Y%m%d');
    
    -- Log archival activity
    INSERT INTO sales_mart.mart_refresh_log (
        mart_name, records_processed, status
    ) VALUES (
        'sales_mart_archive', v_archived_count, 'SUCCESS'
    );
    
    SELECT CONCAT('Archived ', v_archived_count, ' records') as result;
END$$
DELIMITER ;

-- ============================================================================
-- BEST PRACTICES FOR DATA MARTS:
-- 1. Keep data marts focused on specific business domains
-- 2. Denormalize dimensions for better query performance
-- 3. Implement regular refresh schedules
-- 4. Monitor data mart usage and performance
-- 5. Maintain data lineage and documentation
-- 6. Implement proper security and access controls
-- 7. Plan for data archival and retention policies
-- ============================================================================

-- 3-fact_tables.sql
-- Fact Table Design and Implementation in Data Warehousing
-- 
-- This file demonstrates the creation and management of fact tables,
-- which are the central tables in a data warehouse that store measurable,
-- quantitative data for analysis.
--
-- Key Concepts:
-- 1. Fact tables contain foreign keys to dimension tables
-- 2. Fact tables store measures/metrics (numeric values)
-- 3. Fact tables can be transaction, periodic snapshot, or accumulating snapshot
-- 4. Grain definition is crucial for fact table design

-- =====================================================
-- TRANSACTION FACT TABLE EXAMPLE
-- =====================================================
-- Each row represents a single business transaction/event

-- Sales Transaction Fact Table
CREATE TABLE fact_sales_transaction (
    -- Surrogate key for the fact table
    sales_transaction_key BIGINT IDENTITY(1,1) PRIMARY KEY,
    
    -- Foreign keys to dimension tables (dimensional keys)
    date_key INT NOT NULL,
    customer_key INT NOT NULL,
    product_key INT NOT NULL,
    store_key INT NOT NULL,
    employee_key INT NOT NULL,
    promotion_key INT NULL, -- Nullable for transactions without promotions
    
    -- Degenerate dimensions (transaction-level attributes)
    transaction_number VARCHAR(20) NOT NULL,
    receipt_number VARCHAR(15),
    
    -- Facts/Measures (quantitative data)
    quantity_sold DECIMAL(10,2) NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    discount_amount DECIMAL(10,2) DEFAULT 0,
    tax_amount DECIMAL(10,2) NOT NULL,
    total_amount DECIMAL(12,2) NOT NULL,
    cost_amount DECIMAL(10,2) NOT NULL,
    profit_amount AS (total_amount - cost_amount - discount_amount), -- Calculated measure
    
    -- Audit columns
    created_date DATETIME2 DEFAULT GETDATE(),
    updated_date DATETIME2 DEFAULT GETDATE(),
    
    -- Foreign key constraints
    CONSTRAINT FK_fact_sales_date FOREIGN KEY (date_key) REFERENCES dim_date(date_key),
    CONSTRAINT FK_fact_sales_customer FOREIGN KEY (customer_key) REFERENCES dim_customer(customer_key),
    CONSTRAINT FK_fact_sales_product FOREIGN KEY (product_key) REFERENCES dim_product(product_key),
    CONSTRAINT FK_fact_sales_store FOREIGN KEY (store_key) REFERENCES dim_store(store_key),
    CONSTRAINT FK_fact_sales_employee FOREIGN KEY (employee_key) REFERENCES dim_employee(employee_key),
    CONSTRAINT FK_fact_sales_promotion FOREIGN KEY (promotion_key) REFERENCES dim_promotion(promotion_key)
);

-- =====================================================
-- PERIODIC SNAPSHOT FACT TABLE EXAMPLE
-- =====================================================
-- Each row represents the state of something at regular intervals

-- Daily Inventory Snapshot Fact Table
CREATE TABLE fact_inventory_daily_snapshot (
    -- Composite primary key (no surrogate key needed)
    date_key INT NOT NULL,
    product_key INT NOT NULL,
    warehouse_key INT NOT NULL,
    
    -- Facts/Measures for inventory metrics
    beginning_inventory_quantity DECIMAL(12,2) NOT NULL,
    ending_inventory_quantity DECIMAL(12,2) NOT NULL,
    units_received DECIMAL(12,2) DEFAULT 0,
    units_sold DECIMAL(12,2) DEFAULT 0,
    units_adjusted DECIMAL(12,2) DEFAULT 0, -- Inventory adjustments
    
    -- Calculated measures
    inventory_turnover_rate DECIMAL(8,4),
    days_supply DECIMAL(8,2),
    
    -- Value measures
    inventory_value_beginning DECIMAL(15,2) NOT NULL,
    inventory_value_ending DECIMAL(15,2) NOT NULL,
    average_unit_cost DECIMAL(10,2) NOT NULL,
    
    -- Audit columns
    snapshot_date DATETIME2 DEFAULT GETDATE(),
    
    -- Primary key constraint
    CONSTRAINT PK_fact_inventory_snapshot PRIMARY KEY (date_key, product_key, warehouse_key),
    
    -- Foreign key constraints
    CONSTRAINT FK_fact_inventory_date FOREIGN KEY (date_key) REFERENCES dim_date(date_key),
    CONSTRAINT FK_fact_inventory_product FOREIGN KEY (product_key) REFERENCES dim_product(product_key),
    CONSTRAINT FK_fact_inventory_warehouse FOREIGN KEY (warehouse_key) REFERENCES dim_warehouse(warehouse_key)
);

-- =====================================================
-- ACCUMULATING SNAPSHOT FACT TABLE EXAMPLE
-- =====================================================
-- Each row represents a process with a defined beginning and end

-- Order Fulfillment Process Fact Table
CREATE TABLE fact_order_fulfillment (
    order_key BIGINT IDENTITY(1,1) PRIMARY KEY,
    
    -- Multiple date keys for different process milestones
    order_date_key INT NOT NULL,
    payment_date_key INT NULL,
    shipment_date_key INT NULL,
    delivery_date_key INT NULL,
    
    -- Dimension keys
    customer_key INT NOT NULL,
    product_key INT NOT NULL,
    shipper_key INT NULL,
    
    -- Degenerate dimensions
    order_number VARCHAR(20) NOT NULL,
    tracking_number VARCHAR(30),
    
    -- Process measures
    quantity_ordered DECIMAL(10,2) NOT NULL,
    quantity_shipped DECIMAL(10,2),
    quantity_delivered DECIMAL(10,2),
    
    -- Time lag measures (in days)
    order_to_payment_lag AS DATEDIFF(day, order_date_key, payment_date_key),
    payment_to_shipment_lag AS DATEDIFF(day, payment_date_key, shipment_date_key),
    shipment_to_delivery_lag AS DATEDIFF(day, shipment_date_key, delivery_date_key),
    order_to_delivery_lag AS DATEDIFF(day, order_date_key, delivery_date_key),
    
    -- Financial measures
    order_amount DECIMAL(12,2) NOT NULL,
    shipping_cost DECIMAL(8,2),
    
    -- Status indicators
    is_order_complete BIT DEFAULT 0,
    is_shipped BIT DEFAULT 0,
    is_delivered BIT DEFAULT 0,
    
    -- Audit columns
    created_date DATETIME2 DEFAULT GETDATE(),
    updated_date DATETIME2 DEFAULT GETDATE()
);

-- =====================================================
-- FACTLESS FACT TABLE EXAMPLE
-- =====================================================
-- Records events or conditions without numeric measures

-- Student Course Enrollment (Coverage Table)
CREATE TABLE fact_student_enrollment (
    enrollment_key BIGINT IDENTITY(1,1) PRIMARY KEY,
    
    -- Dimension keys
    student_key INT NOT NULL,
    course_key INT NOT NULL,
    instructor_key INT NOT NULL,
    semester_key INT NOT NULL,
    enrollment_date_key INT NOT NULL,
    
    -- Degenerate dimensions
    enrollment_id VARCHAR(20) NOT NULL,
    section_number VARCHAR(10),
    
    -- Status flags (the "facts" in this factless table)
    is_enrolled BIT DEFAULT 1,
    is_waitlisted BIT DEFAULT 0,
    is_dropped BIT DEFAULT 0,
    is_completed BIT DEFAULT 0,
    
    -- Audit information
    created_date DATETIME2 DEFAULT GETDATE(),
    
    -- Constraints
    CONSTRAINT FK_fact_enrollment_student FOREIGN KEY (student_key) REFERENCES dim_student(student_key),
    CONSTRAINT FK_fact_enrollment_course FOREIGN KEY (course_key) REFERENCES dim_course(course_key),
    CONSTRAINT FK_fact_enrollment_instructor FOREIGN KEY (instructor_key) REFERENCES dim_instructor(instructor_key),
    CONSTRAINT FK_fact_enrollment_semester FOREIGN KEY (semester_key) REFERENCES dim_semester(semester_key),
    CONSTRAINT FK_fact_enrollment_date FOREIGN KEY (enrollment_date_key) REFERENCES dim_date(date_key)
);

-- =====================================================
-- FACT TABLE INDEXING STRATEGIES
-- =====================================================

-- Clustered index on date for time-series queries
CREATE CLUSTERED INDEX IX_fact_sales_date_clustered 
ON fact_sales_transaction (date_key);

-- Non-clustered indexes for common query patterns
CREATE NONCLUSTERED INDEX IX_fact_sales_customer 
ON fact_sales_transaction (customer_key, date_key) 
INCLUDE (quantity_sold, total_amount);

CREATE NONCLUSTERED INDEX IX_fact_sales_product 
ON fact_sales_transaction (product_key, date_key) 
INCLUDE (quantity_sold, total_amount, profit_amount);

-- Covering index for common aggregation queries
CREATE NONCLUSTERED INDEX IX_fact_sales_covering 
ON fact_sales_transaction (date_key, store_key) 
INCLUDE (quantity_sold, total_amount, profit_amount, cost_amount);

-- =====================================================
-- FACT TABLE DATA QUALITY CHECKS
-- =====================================================

-- Check for orphaned records (referential integrity)
CREATE VIEW vw_fact_sales_orphans AS
SELECT 
    'Missing Customer' as issue_type,
    COUNT(*) as record_count
FROM fact_sales_transaction f
LEFT JOIN dim_customer c ON f.customer_key = c.customer_key
WHERE c.customer_key IS NULL

UNION ALL

SELECT 
    'Missing Product' as issue_type,
    COUNT(*) as record_count
FROM fact_sales_transaction f
LEFT JOIN dim_product p ON f.product_key = p.product_key
WHERE p.product_key IS NULL;

-- Check for data anomalies
CREATE VIEW vw_fact_sales_anomalies AS
SELECT 
    'Negative Quantity' as anomaly_type,
    COUNT(*) as record_count
FROM fact_sales_transaction
WHERE quantity_sold < 0

UNION ALL

SELECT 
    'Zero Total Amount' as anomaly_type,
    COUNT(*) as record_count
FROM fact_sales_transaction
WHERE total_amount = 0

UNION ALL

SELECT 
    'Profit Margin > 100%' as anomaly_type,
    COUNT(*) as record_count
FROM fact_sales_transaction
WHERE profit_amount > total_amount;

-- =====================================================
-- SAMPLE ETL PROCEDURES FOR FACT TABLES
-- =====================================================

-- Procedure to load transaction fact table
CREATE PROCEDURE sp_load_fact_sales_transaction
    @load_date DATE
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Insert new sales transactions
        INSERT INTO fact_sales_transaction (
            date_key, customer_key, product_key, store_key, 
            employee_key, promotion_key, transaction_number,
            receipt_number, quantity_sold, unit_price,
            discount_amount, tax_amount, total_amount, cost_amount
        )
        SELECT 
            dd.date_key,
            dc.customer_key,
            dp.product_key,
            ds.store_key,
            de.employee_key,
            dpr.promotion_key,
            st.transaction_number,
            st.receipt_number,
            st.quantity_sold,
            st.unit_price,
            st.discount_amount,
            st.tax_amount,
            st.total_amount,
            st.cost_amount
        FROM staging.sales_transactions st
        INNER JOIN dim_date dd ON CAST(st.transaction_date AS DATE) = dd.full_date
        INNER JOIN dim_customer dc ON st.customer_id = dc.customer_business_key
        INNER JOIN dim_product dp ON st.product_id = dp.product_business_key
        INNER JOIN dim_store ds ON st.store_id = ds.store_business_key
        INNER JOIN dim_employee de ON st.employee_id = de.employee_business_key
        LEFT JOIN dim_promotion dpr ON st.promotion_code = dpr.promotion_code
        WHERE CAST(st.transaction_date AS DATE) = @load_date
        AND NOT EXISTS (
            SELECT 1 FROM fact_sales_transaction f 
            WHERE f.transaction_number = st.transaction_number
        );
        
        COMMIT TRANSACTION;
        
        PRINT 'Successfully loaded ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' records';
        
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;

-- =====================================================
-- FACT TABLE AGGREGATION EXAMPLES
-- =====================================================

-- Daily sales summary
CREATE VIEW vw_daily_sales_summary AS
SELECT 
    d.full_date,
    d.day_of_week,
    d.month_name,
    d.year,
    COUNT(*) as transaction_count,
    SUM(f.quantity_sold) as total_quantity,
    SUM(f.total_amount) as total_sales,
    SUM(f.profit_amount) as total_profit,
    AVG(f.total_amount) as avg_transaction_amount,
    SUM(f.total_amount) / SUM(f.quantity_sold) as avg_price_per_unit
FROM fact_sales_transaction f
INNER JOIN dim_date d ON f.date_key = d.date_key
GROUP BY 
    d.date_key, d.full_date, d.day_of_week, 
    d.month_name, d.year;

-- Product performance analysis
CREATE VIEW vw_product_performance AS
SELECT 
    p.product_name,
    p.category_name,
    p.brand_name,
    COUNT(*) as transaction_count,
    SUM(f.quantity_sold) as total_quantity_sold,
    SUM(f.total_amount) as total_revenue,
    SUM(f.profit_amount) as total_profit,
    AVG(f.unit_price) as avg_selling_price,
    SUM(f.profit_amount) / NULLIF(SUM(f.total_amount), 0) * 100 as profit_margin_percent
FROM fact_sales_transaction f
INNER JOIN dim_product p ON f.product_key = p.product_key
GROUP BY 
    p.product_key, p.product_name, p.category_name, p.brand_name;

-- 4-dimension_tables.sql
-- Dimension Table Design and Implementation in Data Warehousing
-- 
-- This file demonstrates the creation and management of dimension tables,
-- which provide descriptive context for the facts in a data warehouse.
--
-- Key Concepts:
-- 1. Dimension tables contain descriptive attributes
-- 2. They use surrogate keys as primary keys
-- 3. They store business keys from source systems
-- 4. They support slowly changing dimensions (SCD)
-- 5. They enable drill-down and roll-up operations

-- =====================================================
-- DATE DIMENSION TABLE
-- =====================================================
-- The most common dimension in data warehousing

CREATE TABLE dim_date (
    -- Surrogate key (artificial primary key)
    date_key INT PRIMARY KEY,
    
    -- Natural key (business key)
    full_date DATE NOT NULL UNIQUE,
    
    -- Date attributes for various groupings and analysis
    day_of_month TINYINT NOT NULL,
    day_of_year SMALLINT NOT NULL,
    day_of_week TINYINT NOT NULL, -- 1=Sunday, 7=Saturday
    day_name VARCHAR(10) NOT NULL, -- Monday, Tuesday, etc.
    day_abbreviation CHAR(3) NOT NULL, -- Mon, Tue, etc.
    
    week_of_year TINYINT NOT NULL,
    week_of_month TINYINT NOT NULL,
    
    month_number TINYINT NOT NULL,
    month_name VARCHAR(10) NOT NULL, -- January, February, etc.
    month_abbreviation CHAR(3) NOT NULL, -- Jan, Feb, etc.
    
    quarter_number TINYINT NOT NULL,
    quarter_name VARCHAR(10) NOT NULL, -- Quarter 1, Quarter 2, etc.
    
    year SMALLINT NOT NULL,
    
    -- Business calendar attributes
    is_weekend BIT NOT NULL,
    is_holiday BIT NOT NULL DEFAULT 0,
    holiday_name VARCHAR(50) NULL,
    
    -- Fiscal calendar attributes (assuming fiscal year starts in July)
    fiscal_year SMALLINT NOT NULL,
    fiscal_quarter TINYINT NOT NULL,
    fiscal_month TINYINT NOT NULL,
    fiscal_day_of_year SMALLINT NOT NULL,
    
    -- Formatted date strings for reporting
    date_formatted_short VARCHAR(10) NOT NULL, -- MM/DD/YYYY
    date_formatted_long VARCHAR(30) NOT NULL, -- Monday, January 01, 2024
    
    -- Audit columns
    created_date DATETIME2 DEFAULT GETDATE(),
    updated_date DATETIME2 DEFAULT GETDATE()
);

-- =====================================================
-- CUSTOMER DIMENSION TABLE (SCD Type 2)
-- =====================================================
-- Tracks historical changes to customer attributes

CREATE TABLE dim_customer (
    -- Surrogate key
    customer_key INT IDENTITY(1,1) PRIMARY KEY,
    
    -- Business key from source system
    customer_business_key VARCHAR(20) NOT NULL,
    
    -- Customer attributes
    customer_name VARCHAR(100) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    middle_name VARCHAR(50) NULL,
    
    -- Contact information
    email_address VARCHAR(100) NULL,
    phone_number VARCHAR(20) NULL,
    
    -- Address information (can change over time)
    address_line1 VARCHAR(100) NULL,
    address_line2 VARCHAR(100) NULL,
    city VARCHAR(50) NULL,
    state_province VARCHAR(50) NULL,
    postal_code VARCHAR(20) NULL,
    country VARCHAR(50) NULL,
    
    -- Demographic information
    date_of_birth DATE NULL,
    age_range VARCHAR(20) NULL, -- 18-25, 26-35, etc.
    gender CHAR(1) NULL, -- M, F, O
    marital_status VARCHAR(20) NULL,
    
    -- Customer segmentation
    customer_segment VARCHAR(30) NULL, -- Premium, Standard, Basic
    customer_tier VARCHAR(20) NULL, -- Gold, Silver, Bronze
    credit_rating VARCHAR(10) NULL, -- A, B, C, D
    
    -- SCD Type 2 attributes
    effective_date DATE NOT NULL DEFAULT GETDATE(),
    expiry_date DATE NULL, -- NULL for current record
    is_current BIT NOT NULL DEFAULT 1,
    
    -- Change tracking
    change_reason VARCHAR(100) NULL,
    
    -- Audit columns
    created_date DATETIME2 DEFAULT GETDATE(),
    updated_date DATETIME2 DEFAULT GETDATE(),
    
    -- Constraints
    CONSTRAINT CK_dim_customer_scd CHECK (
        (is_current = 1 AND expiry_date IS NULL) OR 
        (is_current = 0 AND expiry_date IS NOT NULL)
    )
);

-- Index for business key lookups
CREATE NONCLUSTERED INDEX IX_dim_customer_business_key 
ON dim_customer (customer_business_key, is_current);

-- =====================================================
-- PRODUCT DIMENSION TABLE (SCD Type 1 & 2 Mixed)
-- =====================================================
-- Product catalog with hierarchical structure

CREATE TABLE dim_product (
    -- Surrogate key
    product_key INT IDENTITY(1,1) PRIMARY KEY,
    
    -- Business key
    product_business_key VARCHAR(20) NOT NULL,
    
    -- Product identification
    product_name VARCHAR(100) NOT NULL,
    product_description TEXT NULL,
    product_code VARCHAR(30) NULL,
    universal_product_code VARCHAR(20) NULL, -- UPC/Barcode
    
    -- Product hierarchy (for drill-down/roll-up)
    category_id INT NULL,
    category_name VARCHAR(50) NULL,
    subcategory_id INT NULL,
    subcategory_name VARCHAR(50) NULL,
    brand_id INT NULL,
    brand_name VARCHAR(50) NULL,
    
    -- Product attributes
    product_color VARCHAR(30) NULL,
    product_size VARCHAR(20) NULL,
    product_weight DECIMAL(8,2) NULL,
    product_dimensions VARCHAR(50) NULL,
    
    -- Pricing information (SCD Type 1 - always current)
    standard_cost DECIMAL(10,2) NULL,
    list_price DECIMAL(10,2) NULL,
    
    -- Product status (SCD Type 2 - track changes)
    product_status VARCHAR(20) NOT NULL DEFAULT 'Active', -- Active, Discontinued, Seasonal
    
    -- SCD Type 2 attributes
    effective_date DATE NOT NULL DEFAULT GETDATE(),
    expiry_date DATE NULL,
    is_current BIT NOT NULL DEFAULT 1,
    
    -- Audit columns
    created_date DATETIME2 DEFAULT GETDATE(),
    updated_date DATETIME2 DEFAULT GETDATE()
);

-- =====================================================
-- EMPLOYEE DIMENSION TABLE
-- =====================================================
-- Staff information for sales attribution

CREATE TABLE dim_employee (
    -- Surrogate key
    employee_key INT IDENTITY(1,1) PRIMARY KEY,
    
    -- Business key
    employee_business_key VARCHAR(20) NOT NULL UNIQUE,
    
    -- Personal information
    employee_name VARCHAR(100) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    
    -- Employment information
    employee_id VARCHAR(20) NOT NULL,
    job_title VARCHAR(50) NULL,
    department VARCHAR(50) NULL,
    manager_name VARCHAR(100) NULL,
    manager_employee_key INT NULL, -- Self-referencing for hierarchy
    
    -- Employment dates
    hire_date DATE NOT NULL,
    termination_date DATE NULL,
    
    -- Employment status
    employment_status VARCHAR(20) NOT NULL DEFAULT 'Active', -- Active, Terminated, On Leave
    employment_type VARCHAR(20) NULL, -- Full-time, Part-time, Contract
    
    -- Contact information
    work_email VARCHAR(100) NULL,
    work_phone VARCHAR(20) NULL,
    
    -- Location
    work_location VARCHAR(50) NULL,
    office_number VARCHAR(20) NULL,
    
    -- Performance indicators
    sales_territory VARCHAR(50) NULL,
    commission_rate DECIMAL(5,4) NULL,
    
    -- Audit columns
    created_date DATETIME2 DEFAULT GETDATE(),
    updated_date DATETIME2 DEFAULT GETDATE(),
    
    -- Self-referencing foreign key for manager hierarchy
    CONSTRAINT FK_dim_employee_manager FOREIGN KEY (manager_employee_key) 
        REFERENCES dim_employee(employee_key)
);

-- =====================================================
-- STORE/LOCATION DIMENSION TABLE
-- =====================================================
-- Physical and virtual store locations

CREATE TABLE dim_store (
    -- Surrogate key
    store_key INT IDENTITY(1,1) PRIMARY KEY,
    
    -- Business key
    store_business_key VARCHAR(20) NOT NULL UNIQUE,
    
    -- Store identification
    store_name VARCHAR(100) NOT NULL,
    store_number VARCHAR(20) NOT NULL,
    store_type VARCHAR(30) NULL, -- Retail, Outlet, Online, Warehouse
    
    -- Location information
    address_line1 VARCHAR(100) NULL,
    address_line2 VARCHAR(100) NULL,
    city VARCHAR(50) NULL,
    state_province VARCHAR(50) NULL,
    postal_code VARCHAR(20) NULL,
    country VARCHAR(50) NULL,
    
    -- Geographic hierarchy for regional analysis
    region VARCHAR(50) NULL,
    district VARCHAR(50) NULL,
    territory VARCHAR(50) NULL,
    
    -- Store characteristics
    store_size_sqft INT NULL,
    store_format VARCHAR(30) NULL, -- Superstore, Convenience, Express
    opening_date DATE NULL,
    closing_date DATE NULL,
    
    -- Store manager information
    store_manager_name VARCHAR(100) NULL,
    store_manager_key INT NULL,
    
    -- Operational information
    is_active BIT NOT NULL DEFAULT 1,
    has_pharmacy BIT DEFAULT 0,
    has_gas_station BIT DEFAULT 0,
    is_24_hours BIT DEFAULT 0,
    
    -- Contact information
    store_phone VARCHAR(20) NULL,
    store_email VARCHAR(100) NULL,
    
    -- Audit columns
    created_date DATETIME2 DEFAULT GETDATE(),
    updated_date DATETIME2 DEFAULT GETDATE(),
    
    -- Foreign key to employee dimension for manager
    CONSTRAINT FK_dim_store_manager FOREIGN KEY (store_manager_key) 
        REFERENCES dim_employee(employee_key)
);

-- =====================================================
-- PROMOTION DIMENSION TABLE
-- =====================================================
-- Marketing promotions and campaigns

CREATE TABLE dim_promotion (
    -- Surrogate key
    promotion_key INT IDENTITY(1,1) PRIMARY KEY,
    
    -- Business key
    promotion_code VARCHAR(20) NOT NULL UNIQUE,
    
    -- Promotion details
    promotion_name VARCHAR(100) NOT NULL,
    promotion_description TEXT NULL,
    promotion_type VARCHAR(30) NULL, -- Discount, BOGO, Coupon, Seasonal
    
    -- Discount information
    discount_type VARCHAR(20) NULL, -- Percentage, Fixed Amount, Free Shipping
    discount_amount DECIMAL(10,2) NULL,
    discount_percentage DECIMAL(5,2) NULL,
    
    -- Promotion period
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    
    -- Promotion scope
    applies_to_product VARCHAR(100) NULL, -- All, Category, Specific Products
    minimum_purchase_amount DECIMAL(10,2) NULL,
    maximum_discount_amount DECIMAL(10,2) NULL,
    
    -- Campaign information
    campaign_name VARCHAR(100) NULL,
    marketing_channel VARCHAR(50) NULL, -- Email, Social Media, Print, TV
    
    -- Status
    promotion_status VARCHAR(20) NOT NULL DEFAULT 'Active', -- Active, Inactive, Expired
    
    -- Usage limits
    max_uses_per_customer INT NULL,
    max_total_uses INT NULL,
    
    -- Audit columns
    created_date DATETIME2 DEFAULT GETDATE(),
    updated_date DATETIME2 DEFAULT GETDATE()
);

-- =====================================================
-- JUNK DIMENSION EXAMPLE
-- =====================================================
-- Combines low-cardinality flags into a single dimension

CREATE TABLE dim_transaction_type (
    -- Surrogate key
    transaction_type_key INT IDENTITY(1,1) PRIMARY KEY,
    
    -- Junk dimension attributes (combinations of flags)
    payment_method VARCHAR(20) NOT NULL, -- Cash, Credit, Debit, Check
    transaction_channel VARCHAR(20) NOT NULL, -- In-Store, Online, Phone, Mobile
    is_return BIT NOT NULL DEFAULT 0,
    is_exchange BIT NOT NULL DEFAULT 0,
    is_void BIT NOT NULL DEFAULT 0,
    is_layaway BIT NOT NULL DEFAULT 0,
    requires_signature BIT NOT NULL DEFAULT 0,
    
    -- Derived description for reporting
    transaction_type_description AS (
        CASE 
            WHEN is_return = 1 THEN 'Return - ' + payment_method + ' - ' + transaction_channel
            WHEN is_exchange = 1 THEN 'Exchange - ' + payment_method + ' - ' + transaction_channel
            WHEN is_void = 1 THEN 'Void - ' + payment_method + ' - ' + transaction_channel
            ELSE 'Sale - ' + payment_method + ' - ' + transaction_channel
        END
    ),
    
    -- Audit columns
    created_date DATETIME2 DEFAULT GETDATE()
);

-- =====================================================
-- DIMENSION TABLE UTILITY PROCEDURES
-- =====================================================

-- Procedure to handle SCD Type 2 updates for customer dimension
CREATE PROCEDURE sp_update_customer_scd2
    @customer_business_key VARCHAR(20),
    @customer_name VARCHAR(100),
    @first_name VARCHAR(50),
    @last_name VARCHAR(50),
    @email_address VARCHAR(100),
    @phone_number VARCHAR(20),
    @address_line1 VARCHAR(100),
    @city VARCHAR(50),
    @state_province VARCHAR(50),
    @postal_code VARCHAR(20),
    @country VARCHAR(50),
    @customer_segment VARCHAR(30),
    @change_reason VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @current_customer_key INT;
    DECLARE @address_changed BIT = 0;
    DECLARE @segment_changed BIT = 0;
    
    -- Check if customer exists and what changed
    SELECT 
        @current_customer_key = customer_key,
        @address_changed = CASE 
            WHEN address_line1 != @address_line1 
                OR city != @city 
                OR state_province != @state_province 
                OR postal_code != @postal_code 
                OR country != @country THEN 1 
            ELSE 0 END,
        @segment_changed = CASE 
            WHEN customer_segment != @customer_segment THEN 1 
            ELSE 0 END
    FROM dim_customer
WHERE is_current = 1;

-- Product hierarchy view for drill-down analysis
CREATE VIEW vw_product_hierarchy AS
SELECT 
    p.product_key,
    p.product_business_key,
    p.product_name,
    p.category_name,
    p.subcategory_name,
    p.brand_name,
    p.product_status,
    p.list_price,
    p.standard_cost,
    CASE 
        WHEN p.list_price > 0 THEN ((p.list_price - p.standard_cost) / p.list_price) * 100
        ELSE 0 
    END as profit_margin_percent
FROM dim_product p
WHERE is_current = 1;

-- Store regional hierarchy view
CREATE VIEW vw_store_hierarchy AS
SELECT 
    s.store_key,
    s.store_business_key,
    s.store_name,
    s.store_type,
    s.city,
    s.state_province,
    s.country,
    s.region,
    s.district,
    s.territory,
    s.store_size_sqft,
    s.is_active,
    e.employee_name as manager_name
FROM dim_store s
LEFT JOIN dim_employee e ON s.store_manager_key = e.employee_key
WHERE s.is_active = 1; 
    WHERE customer_business_key = @customer_business_key 
        AND is_current = 1;
    
    -- If significant attributes changed, create new record (SCD Type 2)
    IF @address_changed = 1 OR @segment_changed = 1
    BEGIN
        -- Expire current record
        UPDATE dim_customer 
        SET 
            expiry_date = GETDATE(),
            is_current = 0,
            updated_date = GETDATE()
        WHERE customer_key = @current_customer_key;
        
        -- Insert new current record
        INSERT INTO dim_customer (
            customer_business_key, customer_name, first_name, last_name,
            email_address, phone_number, address_line1, city, state_province,
            postal_code, country, customer_segment, change_reason
        )
        VALUES (
            @customer_business_key, @customer_name, @first_name, @last_name,
            @email_address, @phone_number, @address_line1, @city, @state_province,
            @postal_code, @country, @customer_segment, @change_reason
        );
    END
    ELSE
    BEGIN
        -- Update non-tracked attributes (SCD Type 1)
        UPDATE dim_customer 
        SET 
            customer_name = @customer_name,
            first_name = @first_name,
            last_name = @last_name,
            email_address = @email_address,
            phone_number = @phone_number,
            updated_date = GETDATE()
        WHERE customer_key = @current_customer_key;
    END
END;

-- =====================================================
-- DIMENSION TABLE VIEWS FOR REPORTING
-- =====================================================

-- Current customers view (SCD Type 2)
CREATE VIEW vw_current_customers AS
SELECT 
    customer_key,
    customer_business_key,
    customer_name,
    first_name,
    last_name,
    email_address,
    phone_number,
    address_line1,
    city,
    state_province,
    postal_code,
    country,
    customer_segment,
    customer_tier,
    credit_rating,
    effective_date
FROM dim_customer

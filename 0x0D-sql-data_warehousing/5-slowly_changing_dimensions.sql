-- 5-slowly_changing_dimensions.sql
-- Slowly Changing Dimensions (SCD) Implementation
-- 
-- This file demonstrates different approaches to handling slowly changing
-- dimensions in data warehousing, including Type 0, Type 1, Type 2, Type 3,
-- Type 4, and Type 6 implementations.
--
-- Key Concepts:
-- 1. SCD Type 0: No changes allowed (retain original values)
-- 2. SCD Type 1: Overwrite old values (no history)
-- 3. SCD Type 2: Add new records (full history)
-- 4. SCD Type 3: Add new columns (limited history)
-- 5. SCD Type 4: History table (separate current and historical)
-- 6. SCD Type 6: Hybrid approach (combines Type 1, 2, and 3)

-- =====================================================
-- SCD TYPE 0 - NO CHANGES ALLOWED
-- =====================================================
-- Original values are never updated - "Set and Forget"

CREATE TABLE dim_customer_type0 (
    customer_key INT IDENTITY(1,1) PRIMARY KEY,
    customer_business_key VARCHAR(20) NOT NULL UNIQUE,
    customer_name VARCHAR(100) NOT NULL,
    
    -- Type 0 attributes - never change once set
    original_signup_date DATE NOT NULL,
    original_signup_channel VARCHAR(50) NOT NULL, -- Web, Store, Phone
    original_customer_segment VARCHAR(30) NOT NULL, -- Premium, Standard, Basic
    original_credit_score_range VARCHAR(20) NOT NULL, -- Excellent, Good, Fair, Poor
    
    -- Other attributes that can change
    current_email VARCHAR(100),
    current_phone VARCHAR(20),
    
    created_date DATETIME2 DEFAULT GETDATE(),
    updated_date DATETIME2 DEFAULT GETDATE()
);

-- Trigger to prevent updates to Type 0 attributes
CREATE TRIGGER tr_prevent_type0_updates
ON dim_customer_type0
AFTER UPDATE
AS
BEGIN
    IF UPDATE(original_signup_date) OR 
       UPDATE(original_signup_channel) OR 
       UPDATE(original_customer_segment) OR 
       UPDATE(original_credit_score_range)
    BEGIN
        RAISERROR('Type 0 attributes cannot be modified', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;

-- =====================================================
-- SCD TYPE 1 - OVERWRITE (NO HISTORY)
-- =====================================================
-- Old values are overwritten with new values

CREATE TABLE dim_customer_type1 (
    customer_key INT IDENTITY(1,1) PRIMARY KEY,
    customer_business_key VARCHAR(20) NOT NULL UNIQUE,
    customer_name VARCHAR(100) NOT NULL,
    
    -- Type 1 attributes - always current, no history
    email_address VARCHAR(100),
    phone_number VARCHAR(20),
    marital_status VARCHAR(20),
    annual_income DECIMAL(12,2),
    
    -- Audit columns
    created_date DATETIME2 DEFAULT GETDATE(),
    updated_date DATETIME2 DEFAULT GETDATE()
);

-- Procedure for Type 1 updates
CREATE PROCEDURE sp_update_customer_type1
    @customer_business_key VARCHAR(20),
    @customer_name VARCHAR(100),
    @email_address VARCHAR(100),
    @phone_number VARCHAR(20),
    @marital_status VARCHAR(20),
    @annual_income DECIMAL(12,2)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Simple update - overwrites existing values
    UPDATE dim_customer_type1
    SET 
        customer_name = @customer_name,
        email_address = @email_address,
        phone_number = @phone_number,
        marital_status = @marital_status,
        annual_income = @annual_income,
        updated_date = GETDATE()
    WHERE customer_business_key = @customer_business_key;
    
    -- Insert if not exists
    IF @@ROWCOUNT = 0
    BEGIN
        INSERT INTO dim_customer_type1 (
            customer_business_key, customer_name, email_address,
            phone_number, marital_status, annual_income
        )
        VALUES (
            @customer_business_key, @customer_name, @email_address,
            @phone_number, @marital_status, @annual_income
        );
    END
END;

-- =====================================================
-- SCD TYPE 2 - ADD NEW RECORDS (FULL HISTORY)
-- =====================================================
-- New records are added for each change, maintaining full history

CREATE TABLE dim_customer_type2 (
    customer_key INT IDENTITY(1,1) PRIMARY KEY,
    customer_business_key VARCHAR(20) NOT NULL,
    customer_name VARCHAR(100) NOT NULL,
    
    -- Type 2 attributes - track all changes
    address_line1 VARCHAR(100),
    city VARCHAR(50),
    state_province VARCHAR(50),
    postal_code VARCHAR(20),
    customer_segment VARCHAR(30),
    customer_status VARCHAR(20),
    
    -- SCD Type 2 control columns
    effective_date DATE NOT NULL DEFAULT GETDATE(),
    expiry_date DATE NULL, -- NULL means current record
    is_current BIT NOT NULL DEFAULT 1,
    version_number INT NOT NULL DEFAULT 1,
    
    -- Change tracking
    change_reason VARCHAR(100),
    source_system_update_date DATETIME2,
    
    -- Audit columns
    created_date DATETIME2 DEFAULT GETDATE(),
    updated_date DATETIME2 DEFAULT GETDATE(),
    
    -- Ensure only one current record per business key
    CONSTRAINT CK_dim_customer_type2_current CHECK (
        (is_current = 1 AND expiry_date IS NULL) OR 
        (is_current = 0 AND expiry_date IS NOT NULL)
    )
);

-- Index for efficient current record lookups
CREATE NONCLUSTERED INDEX IX_dim_customer_type2_current 
ON dim_customer_type2 (customer_business_key, is_current)
INCLUDE (customer_key, customer_name, address_line1, city, customer_segment);

-- Procedure for Type 2 updates
CREATE PROCEDURE sp_update_customer_type2
    @customer_business_key VARCHAR(20),
    @customer_name VARCHAR(100),
    @address_line1 VARCHAR(100),
    @city VARCHAR(50),
    @state_province VARCHAR(50),
    @postal_code VARCHAR(20),
    @customer_segment VARCHAR(30),
    @customer_status VARCHAR(20),
    @change_reason VARCHAR(100) = NULL,
    @source_update_date DATETIME2 = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET @source_update_date = ISNULL(@source_update_date, GETDATE());
    
    DECLARE @current_customer_key INT;
    DECLARE @current_version INT;
    DECLARE @has_changes BIT = 0;
    
    BEGIN TRANSACTION;
    
    BEGIN TRY
        -- Get current record
        SELECT 
            @current_customer_key = customer_key,
            @current_version = version_number,
            @has_changes = CASE 
                WHEN address_line1 != @address_line1 
                    OR city != @city 
                    OR state_province != @state_province 
                    OR postal_code != @postal_code 
                    OR customer_segment != @customer_segment 
                    OR customer_status != @customer_status 
                THEN 1 
                ELSE 0 
            END
        FROM dim_customer_type2
        WHERE customer_business_key = @customer_business_key 
            AND is_current = 1;
        
        IF @current_customer_key IS NOT NULL AND @has_changes = 1
        BEGIN
            -- Expire current record
            UPDATE dim_customer_type2
            SET 
                expiry_date = @source_update_date,
                is_current = 0,
                updated_date = GETDATE()
            WHERE customer_key = @current_customer_key;
            
            -- Insert new current record
            INSERT INTO dim_customer_type2 (
                customer_business_key, customer_name, address_line1,
                city, state_province, postal_code, customer_segment,
                customer_status, version_number, change_reason,
                source_system_update_date, effective_date
            )
            VALUES (
                @customer_business_key, @customer_name, @address_line1,
                @city, @state_province, @postal_code, @customer_segment,
                @customer_status, @current_version + 1, @change_reason,
                @source_update_date, @source_update_date
            );
        END
        ELSE IF @current_customer_key IS NULL
        BEGIN
            -- Insert new customer
            INSERT INTO dim_customer_type2 (
                customer_business_key, customer_name, address_line1,
                city, state_province, postal_code, customer_segment,
                customer_status, change_reason, source_system_update_date
            )
            VALUES (
                @customer_business_key, @customer_name, @address_line1,
                @city, @state_province, @postal_code, @customer_segment,
                @customer_status, 'New Customer', @source_update_date
            );
        END
        -- If no changes, do nothing (could update non-SCD attributes here)
        
        COMMIT TRANSACTION;
        
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;

-- =====================================================
-- SCD TYPE 3 - ADD NEW COLUMNS (LIMITED HISTORY)
-- =====================================================
-- Keep current and previous values in separate columns

CREATE TABLE dim_customer_type3 (
    customer_key INT IDENTITY(1,1) PRIMARY KEY,
    customer_business_key VARCHAR(20) NOT NULL UNIQUE,
    customer_name VARCHAR(100) NOT NULL,
    
    -- Current attributes
    current_customer_segment VARCHAR(30),
    current_credit_rating VARCHAR(10),
    current_annual_income DECIMAL(12,2),
    
    -- Previous attributes (Type 3 - limited history)
    previous_customer_segment VARCHAR(30),
    previous_credit_rating VARCHAR(10),
    previous_annual_income DECIMAL(12,2),
    
    -- Change tracking
    segment_change_date DATE,
    credit_rating_change_date DATE,
    income_change_date DATE,
    
    -- Audit columns
    created_date DATETIME2 DEFAULT GETDATE(),
    updated_date DATETIME2 DEFAULT GETDATE()
);

-- Procedure for Type 3 updates
CREATE PROCEDURE sp_update_customer_type3
    @customer_business_key VARCHAR(20),
    @customer_name VARCHAR(100),
    @customer_segment VARCHAR(30),
    @credit_rating VARCHAR(10),
    @annual_income DECIMAL(12,2)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @change_date DATE = GETDATE();
    
    UPDATE dim_customer_type3
    SET 
        customer_name = @customer_name,
        
        -- Update current values and shift to previous if changed
        previous_customer_segment = CASE 
            WHEN current_customer_segment != @customer_segment 
            THEN current_customer_segment 
            ELSE previous_customer_segment 
        END,
        current_customer_segment = @customer_segment,
        segment_change_date = CASE 
            WHEN current_customer_segment != @customer_segment 
            THEN @change_date 
            ELSE segment_change_date 
        END,
        
        previous_credit_rating = CASE 
            WHEN current_credit_rating != @credit_rating 
            THEN current_credit_rating 
            ELSE previous_credit_rating 
        END,
        current_credit_rating = @credit_rating,
        credit_rating_change_date = CASE 
            WHEN current_credit_rating != @credit_rating 
            THEN @change_date 
            ELSE credit_rating_change_date 
        END,
        
        previous_annual_income = CASE 
            WHEN current_annual_income != @annual_income 
            THEN current_annual_income 
            ELSE previous_annual_income 
        END,
        current_annual_income = @annual_income,
        income_change_date = CASE 
            WHEN current_annual_income != @annual_income 
            THEN @change_date 
            ELSE income_change_date 
        END,
        
        updated_date = GETDATE()
    WHERE customer_business_key = @customer_business_key;
    
    -- Insert if not exists
    IF @@ROWCOUNT = 0
    BEGIN
        INSERT INTO dim_customer_type3 (
            customer_business_key, customer_name,
            current_customer_segment, current_credit_rating, current_annual_income
        )
        VALUES (
            @customer_business_key, @customer_name,
            @customer_segment, @credit_rating, @annual_income
        );
    END
END;

-- =====================================================
-- SCD TYPE 4 - HISTORY TABLE (SEPARATE TABLES)
-- =====================================================
-- Current and historical data in separate tables

-- Current table
CREATE TABLE dim_customer_current (
    customer_key INT IDENTITY(1,1) PRIMARY KEY,
    customer_business_key VARCHAR(20) NOT NULL UNIQUE,
    customer_name VARCHAR(100) NOT NULL,
    email_address VARCHAR(100),
    phone_number VARCHAR(20),
    address_line1 VARCHAR(100),
    city VARCHAR(50),
    customer_segment VARCHAR(30),
    customer_status VARCHAR(20),
    
    -- Audit columns
    created_date DATETIME2 DEFAULT GETDATE(),
    updated_date DATETIME2 DEFAULT GETDATE()
);

-- History table
CREATE TABLE dim_customer_history (
    history_key INT IDENTITY(1,1) PRIMARY KEY,
    customer_key INT NOT NULL, -- References current table
    customer_business_key VARCHAR(20) NOT NULL,
    customer_name VARCHAR(100) NOT NULL,
    email_address VARCHAR(100),
    phone_number VARCHAR(20),
    address_line1 VARCHAR(100),
    city VARCHAR(50),
    customer_segment VARCHAR(30),
    customer_status VARCHAR(20),
    
    -- History tracking
    effective_date DATETIME2 NOT NULL,
    expiry_date DATETIME2 NOT NULL,
    change_reason VARCHAR(100),
    
    -- Audit columns
    archived_date DATETIME2 DEFAULT GETDATE(),
    
    -- Foreign key to current table
    CONSTRAINT FK_customer_history_current 
        FOREIGN KEY (customer_key) REFERENCES dim_customer_current(customer_key)
);

-- Procedure for Type 4 updates
CREATE PROCEDURE sp_update_customer_type4
    @customer_business_key VARCHAR(20),
    @customer_name VARCHAR(100),
    @email_address VARCHAR(100),
    @phone_number VARCHAR(20),
    @address_line1 VARCHAR(100),
    @city VARCHAR(50),
    @customer_segment VARCHAR(30),
    @customer_status VARCHAR(20),
    @change_reason VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @customer_key INT;
    DECLARE @change_date DATETIME2 = GETDATE();
    
    BEGIN TRANSACTION;
    
    BEGIN TRY
        -- Get current customer key
        SELECT @customer_key = customer_key
        FROM dim_customer_current
        WHERE customer_business_key = @customer_business_key;
        
        IF @customer_key IS NOT NULL
        BEGIN
            -- Archive current record to history
            INSERT INTO dim_customer_history (
                customer_key, customer_business_key, customer_name,
                email_address, phone_number, address_line1, city,
                customer_segment, customer_status, effective_date,
                expiry_date, change_reason
            )
            SELECT 
                customer_key, customer_business_key, customer_name,
                email_address, phone_number, address_line1, city,
                customer_segment, customer_status, created_date,
                @change_date, @change_reason
            FROM dim_customer_current
            WHERE customer_key = @customer_key;
            
            -- Update current record
            UPDATE dim_customer_current
            SET 
                customer_name = @customer_name,
                email_address = @email_address,
                phone_number = @phone_number,
                address_line1 = @address_line1,
                city = @city,
                customer_segment = @customer_segment,
                customer_status = @customer_status,
                updated_date = @change_date
            WHERE customer_key = @customer_key;
        END
        ELSE
        BEGIN
            -- Insert new customer
            INSERT INTO dim_customer_current (
                customer_business_key, customer_name, email_address,
                phone_number, address_line1, city, customer_segment,
                customer_status
            )
            VALUES (
                @customer_business_key, @customer_name, @email_address,
                @phone_number, @address_line1, @city, @customer_segment,
                @customer_status
            );
        END
        
        COMMIT TRANSACTION;
        
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;

-- =====================================================
-- SCD TYPE 6 - HYBRID APPROACH (1+2+3)
-- =====================================================
-- Combines features of Type 1, Type 2, and Type 3

CREATE TABLE dim_customer_type6 (
    customer_key INT IDENTITY(1,1) PRIMARY KEY,
    customer_business_key VARCHAR(20) NOT NULL,
    customer_name VARCHAR(100) NOT NULL,
    
    -- Type 1 attributes (always current)
    email_address VARCHAR(100),
    phone_number VARCHAR(20),
    
    -- Type 2 attributes (historical)
    historical_address_line1 VARCHAR(100),
    historical_city VARCHAR(50),
    historical_customer_segment VARCHAR(30),
    historical_customer_status VARCHAR(20),
    
    -- Type 3 attributes (current + previous)
    current_address_line1 VARCHAR(100),
    current_city VARCHAR(50),
    current_customer_segment VARCHAR(30),
    current_customer_status VARCHAR(20),
    
    -- SCD Type 2 control columns
    effective_date DATE NOT NULL DEFAULT GETDATE(),
    expiry_date DATE NULL,
    is_current BIT NOT NULL DEFAULT 1,
    version_number INT NOT NULL DEFAULT 1,
    
    -- Change tracking
    change_reason VARCHAR(100),
    
    -- Audit columns
    created_date DATETIME2 DEFAULT GETDATE(),
    updated_date DATETIME2 DEFAULT GETDATE(),
    
    CONSTRAINT CK_dim_customer_type6_current CHECK (
        (is_current = 1 AND expiry_date IS NULL) OR 
        (is_current = 0 AND expiry_date IS NOT NULL)
    )
);

-- View to show current records with both current and historical context
CREATE VIEW vw_customer_type6_current AS
SELECT 
    c.customer_key,
    c.customer_business_key,
    c.customer_name,
    c.email_address, -- Type 1 (always current across all versions)
    c.phone_number,  -- Type 1 (always current across all versions)
    c.current_address_line1, -- Type 3 (current value)
    c.current_city,          -- Type 3 (current value)
    c.current_customer_segment, -- Type 3 (current value)
    c.historical_address_line1, -- Type 2 (historical value for this version)
    c.historical_city,          -- Type 2 (historical value for this version)
    c.historical_customer_segment, -- Type 2 (historical value for this version)
    c.effective_date,
    c.version_number
FROM dim_customer_type6 c
WHERE c.is_current = 1;

-- =====================================================
-- SCD UTILITY FUNCTIONS AND VIEWS
-- =====================================================

-- Function to get customer at specific point in time (Type 2)
CREATE FUNCTION fn_get_customer_at_date(
    @customer_business_key VARCHAR(20),
    @as_of_date DATE
)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        customer_key,
        customer_business_key,
        customer_name,
        address_line1,
        city,
        customer_segment,
        effective_date,
        expiry_date,
        version_number
    FROM dim_customer_type2
    WHERE customer_business_key = @customer_business_key
        AND effective_date <= @as_of_date
        AND (expiry_date IS NULL OR expiry_date > @as_of_date)
);

-- View to analyze SCD Type 2 change patterns
CREATE VIEW vw_customer_change_analysis AS
SELECT 
    customer_business_key,
    COUNT(*) as total_versions,
    MIN(effective_date) as first_version_date,
    MAX(effective_date) as latest_version_date,
    DATEDIFF(day, MIN(effective_date), MAX(effective_date)) as days_tracked,
    AVG(DATEDIFF(day, effective_date, ISNULL(expiry_date, GETDATE()))) as avg_version_duration_days,
    STRING_AGG(change_reason, '; ') as change_history
FROM dim_customer_type2
GROUP BY customer_business_key
HAVING COUNT(*) > 1; -- Only customers with changes

-- Data quality check for SCD Type 2
CREATE VIEW vw_scd_type2_quality_check AS
SELECT 
    'Multiple Current Records' as issue_type,
    customer_business_key,
    COUNT(*) as issue_count
FROM dim_customer_type2
WHERE is_current = 1
GROUP BY customer_business_key
HAVING COUNT(*) > 1

UNION ALL

SELECT 
    'Current Record with Expiry Date' as issue_type,
    customer_business_key,
    COUNT(*) as issue_count
FROM dim_customer_type2
WHERE is_current = 1 AND expiry_date IS NOT NULL
GROUP BY customer_business_key

UNION ALL

SELECT 
    'Historical Record without Expiry Date' as issue_type,
    customer_business_key,
    COUNT(*) as issue_count
FROM dim_customer_type2
WHERE is_current = 0 AND expiry_date IS NULL
GROUP BY customer_business_key;

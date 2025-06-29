/*
 * File: 11-data_cleaning.sql
 * Description: Data cleaning techniques and best practices
 * Author: Alpha0-1
 * 
 * This file demonstrates comprehensive data cleaning operations including:
 * - Handling NULL values and missing data
 * - Removing duplicates
 * - Standardizing formats
 * - Correcting data inconsistencies
 * - Outlier detection and handling
 * - Data quality assessment
 */

-- Create sample table with dirty data
CREATE TABLE IF NOT EXISTS dirty_customer_data (
    id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id VARCHAR(20),
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    phone_number VARCHAR(20),
    address VARCHAR(200),
    city VARCHAR(50),
    state VARCHAR(50),
    zip_code VARCHAR(10),
    age INT,
    income DECIMAL(12,2),
    registration_date VARCHAR(20),
    status VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert dirty sample data with various quality issues
INSERT INTO dirty_customer_data 
(customer_id, first_name, last_name, email, phone_number, address, city, state, zip_code, age, income, registration_date, status) 
VALUES
('CUST001', 'john', 'doe', 'john.doe@email.com', '555-123-4567', '123 Main St', 'New York', 'NY', '10001', 25, 50000.00, '2023-01-15', 'active'),
('CUST002', 'JANE', 'SMITH', 'jane.smith@gmail.com', '(555) 234-5678', '456 Oak Ave', 'Los Angeles', 'CA', '90210', 30, 75000.00, '01/20/2023', 'Active'),
('CUST001', 'John', 'Doe', 'john.doe@email.com', '555.123.4567', '123 Main Street', 'New York', 'New York', '10001', 25, 50000.00, '2023-01-15', 'ACTIVE'),
('CUST003', 'bob', '', 'bob@company.com', '555 345 6789', NULL, 'Chicago', 'IL', '60601', NULL, 60000.00, 'March 10, 2023', 'inactive'),
('CUST004', '', 'Johnson', 'mike.johnson@domain.org', '555-456-7890', '789 Pine St', 'Houston', 'TX', '77001', 35, NULL, '2023-04-05', 'active'),
('CUST005', 'Sarah', 'Brown', 'sarah.brown@test.com', '555-567-8901', '321 Elm St', 'Phoenix', 'AZ', '85001', 200, 45000.00, '2023-05-12', 'pending'),
('CUST006', 'Tom', 'Wilson', NULL, '555-678-9012', '654 Maple Ave', 'Philadelphia', 'PA', '19101', 28, -5000.00, '2023-06-18', 'active'),
('CUST007', 'alice', 'davis', 'alice.davis@email.com', '555-789-0123', '987 Cedar Rd', 'San Antonio', 'TX', '78201', 32, 80000.00, '2023-07-22', 'Active'),
('CUST008', 'Charlie', 'Miller', 'charlie.miller@mail.com', '555-890-1234', '147 Birch Ln', 'San Diego', 'CA', '92101', 45, 95000.00, '2023-08-30', 'suspended'),
('CUST009', 'diana', 'taylor', 'diana.taylor@email.com', '555-901-2345', '258 Spruce St', 'Dallas', 'TX', '75201', 29, 70000.00, '2023-09-14', 'active'),
('', 'Emily', 'Anderson', 'emily.anderson@test.org', '555-012-3456', '369 Fir Ave', 'Austin', 'TX', '73301', 33, 65000.00, '2023-10-28', 'active');

-- Data Quality Assessment
-- Check for NULL values in critical fields
SELECT 
    'NULL Analysis' as check_type,
    COUNT(*) as total_records,
    SUM(CASE WHEN customer_id IS NULL OR customer_id = '' THEN 1 ELSE 0 END) as null_customer_id,
    SUM(CASE WHEN first_name IS NULL OR first_name = '' THEN 1 ELSE 0 END) as null_first_name,
    SUM(CASE WHEN last_name IS NULL OR last_name = '' THEN 1 ELSE 0 END) as null_last_name,
    SUM(CASE WHEN email IS NULL OR email = '' THEN 1 ELSE 0 END) as null_email,
    SUM(CASE WHEN phone_number IS NULL THEN 1 ELSE 0 END) as null_phone,
    SUM(CASE WHEN age IS NULL THEN 1 ELSE 0 END) as null_age,
    SUM(CASE WHEN income IS NULL THEN 1 ELSE 0 END) as null_income
FROM dirty_customer_data;

-- Identify duplicate records
SELECT 
    'Duplicate Analysis' as check_type,
    customer_id,
    first_name,
    last_name,
    email,
    COUNT(*) as duplicate_count
FROM dirty_customer_data
WHERE customer_id IS NOT NULL AND customer_id != ''
GROUP BY customer_id, first_name, last_name, email
HAVING COUNT(*) > 1;

-- Check for data inconsistencies
SELECT 
    'Inconsistency Analysis' as check_type,
    COUNT(DISTINCT LOWER(status)) as unique_status_values,
    GROUP_CONCAT(DISTINCT status) as status_variations,
    MIN(age) as min_age,
    MAX(age) as max_age,
    MIN(income) as min_income,
    MAX(income) as max_income
FROM dirty_customer_data;

-- Create cleaned data table
CREATE TABLE IF NOT EXISTS cleaned_customer_data (
    id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id VARCHAR(20) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    full_name VARCHAR(100) GENERATED ALWAYS AS (CONCAT(first_name, ' ', last_name)) STORED,
    email VARCHAR(100),
    phone_number VARCHAR(15),
    address VARCHAR(200),
    city VARCHAR(50),
    state VARCHAR(2),
    zip_code VARCHAR(10),
    age INT,
    income DECIMAL(12,2),
    registration_date DATE,
    status ENUM('active', 'inactive', 'pending', 'suspended') DEFAULT 'pending',
    data_quality_score DECIMAL(3,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_customer (customer_id),
    INDEX idx_email (email),
    INDEX idx_status (status)
);

-- Data Cleaning Process
-- Step 1: Remove exact duplicates and keep the first occurrence
INSERT INTO cleaned_customer_data 
(customer_id, first_name, last_name, email, phone_number, address, city, state, zip_code, age, income, registration_date, status)
SELECT DISTINCT
    -- Clean customer_id: remove empty strings
    CASE 
        WHEN customer_id = '' THEN CONCAT('CUST_', LPAD(ROW_NUMBER() OVER (ORDER BY id), 3, '0'))
        ELSE customer_id
    END as customer_id,
    
    -- Clean first_name: proper case, handle empty
    CASE 
        WHEN first_name IS NULL OR first_name = '' THEN 'Unknown'
        ELSE CONCAT(UPPER(LEFT(first_name, 1)), LOWER(SUBSTRING(first_name, 2)))
    END as first_name,
    
    -- Clean last_name: proper case, handle empty
    CASE 
        WHEN last_name IS NULL OR last_name = '' THEN 'Unknown'
        ELSE CONCAT(UPPER(LEFT(last_name, 1)), LOWER(SUBSTRING(last_name, 2)))
    END as last_name,
    
    -- Clean email: lowercase, validate format
    CASE 
        WHEN email IS NULL OR email = '' THEN NULL
        WHEN email REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,} THEN LOWER(email)
        ELSE NULL
    END as email,
    
    -- Clean phone_number: standardize format
    CASE 
        WHEN phone_number IS NULL THEN NULL
        ELSE CONCAT(
            SUBSTRING(REGEXP_REPLACE(phone_number, '[^0-9]', ''), 1, 3),
            '-',
            SUBSTRING(REGEXP_REPLACE(phone_number, '[^0-9]', ''), 4, 3),
            '-',
            SUBSTRING(REGEXP_REPLACE(phone_number, '[^0-9]', ''), 7, 4)
        )
    END as phone_number,
    
    -- Clean address
    TRIM(address) as address,
    
    -- Clean city: proper case
    CASE 
        WHEN city IS NULL THEN NULL
        ELSE CONCAT(UPPER(LEFT(city, 1)), LOWER(SUBSTRING(city, 2)))
    END as city,
    
    -- Standardize state to 2-letter code
    CASE 
        WHEN UPPER(state) = 'NEW YORK' THEN 'NY'
        WHEN UPPER(state) = 'CALIFORNIA' THEN 'CA'
        WHEN UPPER(state) = 'TEXAS' THEN 'TX'
        WHEN UPPER(state) = 'FLORIDA' THEN 'FL'
        WHEN UPPER(state) = 'ILLINOIS' THEN 'IL'
        WHEN UPPER(state) = 'PENNSYLVANIA' THEN 'PA'
        WHEN UPPER(state) = 'OHIO' THEN 'OH'
        WHEN UPPER(state) = 'GEORGIA' THEN 'GA'
        WHEN UPPER(state) = 'NORTH CAROLINA' THEN 'NC'
        WHEN UPPER(state) = 'MICHIGAN' THEN 'MI'
        WHEN UPPER(state) = 'ARIZONA' THEN 'AZ'
        WHEN LENGTH(state) = 2 THEN UPPER(state)
        ELSE state
    END as state,
    
    -- Clean zip_code
    LEFT(REGEXP_REPLACE(zip_code, '[^0-9]', ''), 5) as zip_code,
    
    -- Clean age: handle outliers
    CASE 
        WHEN age IS NULL THEN NULL
        WHEN age < 0 OR age > 120 THEN NULL
        ELSE age
    END as age,
    
    -- Clean income: handle negative values
    CASE 
        WHEN income IS NULL THEN NULL
        WHEN income < 0 THEN NULL
        ELSE income
    END as income,
    
    -- Clean registration_date: standardize format
    CASE 
        WHEN registration_date LIKE '%/%' THEN STR_TO_DATE(registration_date, '%m/%d/%Y')
        WHEN registration_date LIKE '%-%' THEN STR_TO_DATE(registration_date, '%Y-%m-%d')
        WHEN registration_date LIKE '%,%' THEN STR_TO_DATE(registration_date, '%M %d, %Y')
        ELSE NULL
    END as registration_date,
    
    -- Standardize status
    CASE 
        WHEN LOWER(status) IN ('active', 'Active', 'ACTIVE') THEN 'active'
        WHEN LOWER(status) IN ('inactive', 'Inactive', 'INACTIVE') THEN 'inactive'
        WHEN LOWER(status) IN ('pending', 'Pending', 'PENDING') THEN 'pending'
        WHEN LOWER(status) IN ('suspended', 'Suspended', 'SUSPENDED') THEN 'suspended'
        ELSE 'pending'
    END as status

FROM (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY 
                   COALESCE(NULLIF(customer_id, ''), CONCAT('TEMP_', id)),
                   LOWER(TRIM(COALESCE(first_name, ''))),
                   LOWER(TRIM(COALESCE(last_name, ''))),
                   LOWER(TRIM(COALESCE(email, '')))
               ORDER BY id
           ) as rn
    FROM dirty_customer_data
) ranked
WHERE rn = 1 
  AND NOT (customer_id IS NULL OR customer_id = '')
  AND NOT (first_name IS NULL OR first_name = '')
  AND NOT (last_name IS NULL OR last_name = '');

-- Update data quality scores
UPDATE cleaned_customer_data 
SET data_quality_score = (
    (CASE WHEN customer_id IS NOT NULL AND customer_id != '' THEN 0.2 ELSE 0 END) +
    (CASE WHEN first_name IS NOT NULL AND first_name != '' AND first_name != 'Unknown' THEN 0.15 ELSE 0 END) +
    (CASE WHEN last_name IS NOT NULL AND last_name != '' AND last_name != 'Unknown' THEN 0.15 ELSE 0 END) +
    (CASE WHEN email IS NOT NULL AND email REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,} THEN 0.2 ELSE 0 END) +
    (CASE WHEN phone_number IS NOT NULL THEN 0.1 ELSE 0 END) +
    (CASE WHEN address IS NOT NULL THEN 0.05 ELSE 0 END) +
    (CASE WHEN city IS NOT NULL THEN 0.05 ELSE 0 END) +
    (CASE WHEN state IS NOT NULL THEN 0.05 ELSE 0 END) +
    (CASE WHEN age IS NOT NULL AND age BETWEEN 0 AND 120 THEN 0.05 ELSE 0 END)
);

-- Advanced Data Cleaning Operations

-- Find and handle outliers using IQR method
CREATE TEMPORARY TABLE income_stats AS
SELECT 
    AVG(income) as mean_income,
    STDDEV(income) as std_income,
    COUNT(*) as total_count
FROM cleaned_customer_data 
WHERE income IS NOT NULL;

-- Identify potential outliers
SELECT 
    c.id,
    c.customer_id,
    c.full_name,
    c.income,
    s.mean_income,
    s.std_income,
    ABS(c.income - s.mean_income) / s.std_income as z_score,
    CASE 
        WHEN ABS(c.income - s.mean_income) / s.std_income > 3 THEN 'Extreme Outlier'
        WHEN ABS(c.income - s.mean_income) / s.std_income > 2 THEN 'Moderate Outlier'
        ELSE 'Normal'
    END as outlier_status
FROM cleaned_customer_data c
CROSS JOIN income_stats s
WHERE c.income IS NOT NULL
ORDER BY z_score DESC;

-- Create data quality report
CREATE TABLE IF NOT EXISTS data_quality_report (
    id INT AUTO_INCREMENT PRIMARY KEY,
    report_date DATE,
    metric_name VARCHAR(100),
    metric_value DECIMAL(10,2),
    total_records INT,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert quality metrics
INSERT INTO data_quality_report (report_date, metric_name, metric_value, total_records, notes)
SELECT 
    CURDATE() as report_date,
    'Completeness - Customer ID' as metric_name,
    (COUNT(customer_id) * 100.0 / COUNT(*)) as metric_value,
    COUNT(*) as total_records,
    'Percentage of records with valid customer ID' as notes
FROM cleaned_customer_data
UNION ALL
SELECT 
    CURDATE(),
    'Completeness - Email',
    (COUNT(email) * 100.0 / COUNT(*)),
    COUNT(*),
    'Percentage of records with valid email'
FROM cleaned_customer_data
UNION ALL
SELECT 
    CURDATE(),
    'Completeness - Phone',
    (COUNT(phone_number) * 100.0 / COUNT(*)),
    COUNT(*),
    'Percentage of records with phone number'
FROM cleaned_customer_data
UNION ALL
SELECT 
    CURDATE(),
    'Data Quality Score Average',
    AVG(data_quality_score),
    COUNT(*),
    'Average data quality score across all records'
FROM cleaned_customer_data;

-- Create data cleaning log
CREATE TABLE IF NOT EXISTS data_cleaning_log (
    id INT AUTO_INCREMENT PRIMARY KEY,
    cleaning_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    source_table VARCHAR(50),
    target_table VARCHAR(50),
    records_processed INT,
    records_cleaned INT,
    duplicates_removed INT,
    nulls_handled INT,
    outliers_flagged INT,
    cleaning_rules_applied TEXT
);

-- Log cleaning activities
INSERT INTO data_cleaning_log 
(source_table, target_table, records_processed, records_cleaned, duplicates_removed, nulls_handled, outliers_flagged, cleaning_rules_applied)
SELECT 
    'dirty_customer_data' as source_table,
    'cleaned_customer_data' as target_table,
    (SELECT COUNT(*) FROM dirty_customer_data) as records_processed,
    COUNT(*) as records_cleaned,
    (SELECT COUNT(*) FROM dirty_customer_data) - COUNT(*) as duplicates_removed,
    SUM(CASE WHEN first_name = 'Unknown' OR last_name = 'Unknown' THEN 1 ELSE 0 END) as nulls_handled,
    (SELECT COUNT(*) FROM cleaned_customer_data c 
     CROSS JOIN income_stats s 
     WHERE c.income IS NOT NULL 
     AND ABS(c.income - s.mean_income) / s.std_income > 2) as outliers_flagged,
    'Applied name standardization, email validation, phone formatting, duplicate removal, null handling, outlier detection' as cleaning_rules_applied
FROM cleaned_customer_data;

-- Validation queries after cleaning
SELECT 'After Cleaning - Summary Statistics' as report_section;

SELECT 
    COUNT(*) as total_clean_records,
    COUNT(DISTINCT customer_id) as unique_customers,
    AVG(data_quality_score) as avg_quality_score,
    MIN(data_quality_score) as min_quality_score,
    MAX(data_quality_score) as max_quality_score,
    COUNT(CASE WHEN email IS NOT NULL THEN 1 END) as records_with_email,
    COUNT(CASE WHEN phone_number IS NOT NULL THEN 1 END) as records_with_phone,
    COUNT(CASE WHEN age IS NOT NULL THEN 1 END) as records_with_age,
    COUNT(CASE WHEN income IS NOT NULL THEN 1 END) as records_with_income
FROM cleaned_customer_data;

-- Show data quality by score ranges
SELECT 
    CASE 
        WHEN data_quality_score >= 0.9 THEN 'Excellent (90-100%)'
        WHEN data_quality_score >= 0.8 THEN 'Good (80-89%)'
        WHEN data_quality_score >= 0.7 THEN 'Fair (70-79%)'
        WHEN data_quality_score >= 0.6 THEN 'Poor (60-69%)'
        ELSE 'Very Poor (<60%)'
    END as quality_category,
    COUNT(*) as record_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM cleaned_customer_data), 2) as percentage
FROM cleaned_customer_data
GROUP BY 
    CASE 
        WHEN data_quality_score >= 0.9 THEN 'Excellent (90-100%)'
        WHEN data_quality_score >= 0.8 THEN 'Good (80-89%)'
        WHEN data_quality_score >= 0.7 THEN 'Fair (70-79%)'
        WHEN data_quality_score >= 0.6 THEN 'Poor (60-69%)'
        ELSE 'Very Poor (<60%)'
    END
ORDER BY MIN(data_quality_score) DESC;

-- Create a function for ongoing data cleaning
DELIMITER //
CREATE FUNCTION CalculateDataQuality(
    p_customer_id VARCHAR(20),
    p_first_name VARCHAR(50),
    p_last_name VARCHAR(50),
    p_email VARCHAR(100),
    p_phone VARCHAR(20),
    p_address VARCHAR(200),
    p_city VARCHAR(50),
    p_state VARCHAR(50),
    p_age INT
) RETURNS DECIMAL(3,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE quality_score DECIMAL(3,2) DEFAULT 0.0;
    
    -- Customer ID check
    IF p_customer_id IS NOT NULL AND p_customer_id != '' THEN
        SET quality_score = quality_score + 0.2;
    END IF;
    
    -- Name checks
    IF p_first_name IS NOT NULL AND p_first_name != '' AND p_first_name != 'Unknown' THEN
        SET quality_score = quality_score + 0.15;
    END IF;
    
    IF p_last_name IS NOT NULL AND p_last_name != '' AND p_last_name != 'Unknown' THEN
        SET quality_score = quality_score + 0.15;
    END IF;
    
    -- Email validation
    IF p_email IS NOT NULL AND p_email REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,} THEN
        SET quality_score = quality_score + 0.2;
    END IF;
    
    -- Phone check
    IF p_phone IS NOT NULL THEN
        SET quality_score = quality_score + 0.1;
    END IF;
    
    -- Address components
    IF p_address IS NOT NULL THEN
        SET quality_score = quality_score + 0.05;
    END IF;
    
    IF p_city IS NOT NULL THEN
        SET quality_score = quality_score + 0.05;
    END IF;
    
    IF p_state IS NOT NULL THEN
        SET quality_score = quality_score + 0.05;
    END IF;
    
    -- Age validation
    IF p_age IS NOT NULL AND p_age BETWEEN 0 AND 120 THEN
        SET quality_score = quality_score + 0.05;
    END IF;
    
    RETURN quality_score;
END//
DELIMITER ;

-- Test the quality function
SELECT 
    customer_id,
    full_name,
    data_quality_score as stored_score,
    CalculateDataQuality(
        customer_id, first_name, last_name, email, phone_number,
        address, city, state, age
    ) as calculated_score
FROM cleaned_customer_data
LIMIT 5;

-- Cleanup temporary objects
DROP TEMPORARY TABLE IF EXISTS income_stats;

/*
 * Best Practices for Data Cleaning:
 * 1. Always backup original data before cleaning
 * 2. Document all cleaning rules and transformations
 * 3. Implement data quality scoring
 * 4. Handle different types of missing data appropriately
 * 5. Standardize formats consistently
 * 6. Validate data against business rules
 * 7. Monitor data quality over time
 * 8. Create automated cleaning procedures
 * 9. Flag rather than delete suspicious data
 * 10. Maintain audit trails of cleaning activities
 * 
 * Common Data Quality Issues:
 * - Missing values (NULLs, empty strings)
 * - Duplicate records
 * - Inconsistent formats
 * - Invalid values
 * - Outliers
 * - Inconsistent naming conventions
 * - Data type mismatches
 * - Referential integrity issues
 */

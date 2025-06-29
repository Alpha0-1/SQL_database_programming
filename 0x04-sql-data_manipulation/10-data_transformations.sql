/*
 * File: 10-data_transformation.sql
 * Description: Data transformation techniques and operations
 * Author: Alpha0-1
 * 
 * This file demonstrates various data transformation methods including:
 * - Data type conversions
 * - String transformations
 * - Date/time transformations
 * - Numeric transformations
 * - Conditional transformations
 * - Aggregation transformations
 */

-- Create sample tables for transformation examples
CREATE TABLE IF NOT EXISTS raw_sales_data (
    id INT AUTO_INCREMENT PRIMARY KEY,
    sale_date VARCHAR(20),
    customer_name VARCHAR(100),
    product_code VARCHAR(10),
    quantity VARCHAR(10),
    unit_price VARCHAR(15),
    region VARCHAR(50),
    salesperson VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample raw data with various formats
INSERT INTO raw_sales_data (sale_date, customer_name, product_code, quantity, unit_price, region, salesperson) VALUES
('2024-01-15', 'john doe', 'P001', '5', '$29.99', 'north', 'Alice Johnson'),
('01/20/2024', 'JANE SMITH', 'P002', '3', '45.50', 'SOUTH', 'bob wilson'),
('2024-02-10', 'Mike Johnson', 'P003', '10', '$15.75', 'East', 'Carol Davis'),
('Feb 25, 2024', 'sarah brown', 'P001', '2', '29.99', 'west', 'DAVID MILLER'),
('2024-03-05', 'Tom Wilson', 'P004', '8', '$78.25', 'North', 'Alice Johnson'),
('03/15/2024', 'emily davis', 'P002', '6', '45.50', 'South', 'Emma Thompson');

-- Data Type Transformations
-- Convert string dates to proper DATE format
SELECT 
    id,
    sale_date as original_date,
    CASE 
        WHEN sale_date LIKE '%/%' THEN STR_TO_DATE(sale_date, '%m/%d/%Y')
        WHEN sale_date LIKE '%-%' THEN STR_TO_DATE(sale_date, '%Y-%m-%d')
        WHEN sale_date LIKE '%,%' THEN STR_TO_DATE(sale_date, '%M %d, %Y')
        ELSE NULL
    END as transformed_date
FROM raw_sales_data;

-- Convert string numbers to numeric types
SELECT 
    id,
    quantity as original_quantity,
    CAST(quantity AS UNSIGNED) as numeric_quantity,
    unit_price as original_price,
    CAST(REPLACE(unit_price, '$', '') AS DECIMAL(10,2)) as numeric_price,
    CAST(quantity AS UNSIGNED) * CAST(REPLACE(unit_price, '$', '') AS DECIMAL(10,2)) as total_amount
FROM raw_sales_data;

-- String Transformations
-- Standardize name formats and case
SELECT 
    id,
    customer_name as original_name,
    CONCAT(
        UPPER(LEFT(customer_name, 1)),
        LOWER(SUBSTRING(customer_name, 2))
    ) as title_case_name,
    UPPER(customer_name) as upper_name,
    LOWER(customer_name) as lower_name,
    -- Proper case for full names
    CONCAT(
        UPPER(LEFT(SUBSTRING_INDEX(customer_name, ' ', 1), 1)),
        LOWER(SUBSTRING(SUBSTRING_INDEX(customer_name, ' ', 1), 2)),
        ' ',
        UPPER(LEFT(SUBSTRING_INDEX(customer_name, ' ', -1), 1)),
        LOWER(SUBSTRING(SUBSTRING_INDEX(customer_name, ' ', -1), 2))
    ) as proper_case_name
FROM raw_sales_data;

-- Region standardization
SELECT 
    id,
    region as original_region,
    CASE 
        WHEN UPPER(region) = 'NORTH' THEN 'Northern'
        WHEN UPPER(region) = 'SOUTH' THEN 'Southern'
        WHEN UPPER(region) = 'EAST' THEN 'Eastern'
        WHEN UPPER(region) = 'WEST' THEN 'Western'
        ELSE 'Unknown'
    END as standardized_region
FROM raw_sales_data;
[O
-- Create transformed data table
CREATE TABLE IF NOT EXISTS transformed_sales_data (
    id INT AUTO_INCREMENT PRIMARY KEY,
    sale_date DATE,
    customer_name VARCHAR(100),
    product_code VARCHAR(10),
    quantity INT,
    unit_price DECIMAL(10,2),
    total_amount DECIMAL(12,2),
    region VARCHAR(20),
    salesperson VARCHAR(100),
    quarter VARCHAR(10),
    month_name VARCHAR(15),
    day_of_week VARCHAR(15),
    price_category VARCHAR(20),
    quantity_tier VARCHAR(15),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert transformed data
INSERT INTO transformed_sales_data (
    sale_date, customer_name, product_code, quantity, unit_price, total_amount,
    region, salesperson, quarter, month_name, day_of_week, price_category, quantity_tier
)
SELECT 
    -- Date transformation
    CASE 
        WHEN sale_date LIKE '%/%' THEN STR_TO_DATE(sale_date, '%m/%d/%Y')
        WHEN sale_date LIKE '%-%' THEN STR_TO_DATE(sale_date, '%Y-%m-%d')
        WHEN sale_date LIKE '%,%' THEN STR_TO_DATE(sale_date, '%M %d, %Y')
        ELSE NULL
    END as sale_date,
    
    -- Name transformation (proper case)
    CONCAT(
        UPPER(LEFT(SUBSTRING_INDEX(customer_name, ' ', 1), 1)),
        LOWER(SUBSTRING(SUBSTRING_INDEX(customer_name, ' ', 1), 2)),
        ' ',
        UPPER(LEFT(SUBSTRING_INDEX(customer_name, ' ', -1), 1)),
        LOWER(SUBSTRING(SUBSTRING_INDEX(customer_name, ' ', -1), 2))
    ) as customer_name,
    
    product_code,
    CAST(quantity AS UNSIGNED) as quantity,
    CAST(REPLACE(unit_price, '$', '') AS DECIMAL(10,2)) as unit_price,
    CAST(quantity AS UNSIGNED) * CAST(REPLACE(unit_price, '$', '') AS DECIMAL(10,2)) as total_amount,
    
    -- Region standardization
    CASE 
        WHEN UPPER(region) = 'NORTH' THEN 'Northern'
        WHEN UPPER(region) = 'SOUTH' THEN 'Southern'
        WHEN UPPER(region) = 'EAST' THEN 'Eastern'
        WHEN UPPER(region) = 'WEST' THEN 'Western'
        ELSE 'Unknown'
    END as region,
    
    -- Salesperson name standardization
    CONCAT(
        UPPER(LEFT(SUBSTRING_INDEX(salesperson, ' ', 1), 1)),
        LOWER(SUBSTRING(SUBSTRING_INDEX(salesperson, ' ', 1), 2)),
        ' ',
        UPPER(LEFT(SUBSTRING_INDEX(salesperson, ' ', -1), 1)),
        LOWER(SUBSTRING(SUBSTRING_INDEX(salesperson, ' ', -1), 2))
    ) as salesperson,
    
    -- Date-based transformations
    CONCAT('Q', QUARTER(
        CASE 
            WHEN sale_date LIKE '%/%' THEN STR_TO_DATE(sale_date, '%m/%d/%Y')
            WHEN sale_date LIKE '%-%' THEN STR_TO_DATE(sale_date, '%Y-%m-%d')
            WHEN sale_date LIKE '%,%' THEN STR_TO_DATE(sale_date, '%M %d, %Y')
            ELSE NULL
        END
    )) as quarter,
    
    MONTHNAME(
        CASE 
            WHEN sale_date LIKE '%/%' THEN STR_TO_DATE(sale_date, '%m/%d/%Y')
            WHEN sale_date LIKE '%-%' THEN STR_TO_DATE(sale_date, '%Y-%m-%d')
            WHEN sale_date LIKE '%,%' THEN STR_TO_DATE(sale_date, '%M %d, %Y')
            ELSE NULL
        END
    ) as month_name,
    
    DAYNAME(
        CASE 
            WHEN sale_date LIKE '%/%' THEN STR_TO_DATE(sale_date, '%m/%d/%Y')
            WHEN sale_date LIKE '%-%' THEN STR_TO_DATE(sale_date, '%Y-%m-%d')
            WHEN sale_date LIKE '%,%' THEN STR_TO_DATE(sale_date, '%M %d, %Y')
            ELSE NULL
        END
    ) as day_of_week,
    
    -- Price categorization
    CASE 
        WHEN CAST(REPLACE(unit_price, '$', '') AS DECIMAL(10,2)) < 25 THEN 'Low'
        WHEN CAST(REPLACE(unit_price, '$', '') AS DECIMAL(10,2)) BETWEEN 25 AND 50 THEN 'Medium'
        WHEN CAST(REPLACE(unit_price, '$', '') AS DECIMAL(10,2)) > 50 THEN 'High'
        ELSE 'Unknown'
    END as price_category,
    
    -- Quantity tier
    CASE 
        WHEN CAST(quantity AS UNSIGNED) <= 3 THEN 'Small'
        WHEN CAST(quantity AS UNSIGNED) BETWEEN 4 AND 7 THEN 'Medium'
        WHEN CAST(quantity AS UNSIGNED) >= 8 THEN 'Large'
        ELSE 'Unknown'
    END as quantity_tier
    
FROM raw_sales_data;

-- Advanced Transformations
-- Pivot transformation - Convert rows to columns
SELECT 
    customer_name,
    SUM(CASE WHEN region = 'Northern' THEN total_amount ELSE 0 END) as northern_sales,
    SUM(CASE WHEN region = 'Southern' THEN total_amount ELSE 0 END) as southern_sales,
    SUM(CASE WHEN region = 'Eastern' THEN total_amount ELSE 0 END) as eastern_sales,
    SUM(CASE WHEN region = 'Western' THEN total_amount ELSE 0 END) as western_sales,
    SUM(total_amount) as total_sales
FROM transformed_sales_data
GROUP BY customer_name;

-- Time-based aggregation transformation
SELECT 
    month_name,
    quarter,
    COUNT(*) as transaction_count,
    SUM(quantity) as total_quantity,
    SUM(total_amount) as total_revenue,
    AVG(total_amount) as avg_transaction_value,
    MIN(total_amount) as min_transaction,
    MAX(total_amount) as max_transaction
FROM transformed_sales_data
GROUP BY month_name, quarter
ORDER BY STR_TO_DATE(CONCAT(month_name, ' 1, 2024'), '%M %d, %Y');

-- Ranking and window function transformations
SELECT 
    customer_name,
    region,
    total_amount,
    RANK() OVER (PARTITION BY region ORDER BY total_amount DESC) as region_rank,
    DENSE_RANK() OVER (ORDER BY total_amount DESC) as overall_rank,
    ROW_NUMBER() OVER (PARTITION BY region ORDER BY sale_date) as transaction_sequence,
    LAG(total_amount) OVER (PARTITION BY customer_name ORDER BY sale_date) as previous_purchase,
    LEAD(total_amount) OVER (PARTITION BY customer_name ORDER BY sale_date) as next_purchase
FROM transformed_sales_data
ORDER BY region, total_amount DESC;

-- Cumulative transformations
SELECT 
    sale_date,
    customer_name,
    total_amount,
    SUM(total_amount) OVER (ORDER BY sale_date) as running_total,
    AVG(total_amount) OVER (ORDER BY sale_date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) as moving_avg_3,
    COUNT(*) OVER (ORDER BY sale_date) as cumulative_transactions
FROM transformed_sales_data
ORDER BY sale_date;

-- Text transformation and cleaning
CREATE TABLE IF NOT EXISTS text_data (
    id INT AUTO_INCREMENT PRIMARY KEY,
    raw_text TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO text_data (raw_text) VALUES
('  Hello World!  '),
('This is a MIXED case STRING'),
('remove@special#characters$here'),
('123-456-7890'),
('email@domain.com'),
('  Multiple   Spaces   Between   Words  ');

-- Text cleaning transformations
SELECT 
    id,
    raw_text,
    TRIM(raw_text) as trimmed_text,
    REPLACE(REPLACE(REPLACE(raw_text, '@', ''), '#', ''), '$', '') as removed_special_chars,
    REGEXP_REPLACE(raw_text, '[^a-zA-Z0-9 ]', '') as alphanumeric_only,
    REGEXP_REPLACE(TRIM(raw_text), ' +', ' ') as single_spaces,
    LENGTH(raw_text) as original_length,
    LENGTH(TRIM(raw_text)) as trimmed_length
FROM text_data;

-- Create a transformation log table
CREATE TABLE IF NOT EXISTS transformation_log (
    id INT AUTO_INCREMENT PRIMARY KEY,
    source_table VARCHAR(50),
    transformation_type VARCHAR(50),
    records_processed INT,
    records_transformed INT,
    transformation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    notes TEXT
);

-- Log transformation activity
INSERT INTO transformation_log (source_table, transformation_type, records_processed, records_transformed, notes)
SELECT 
    'raw_sales_data' as source_table,
    'data_standardization' as transformation_type,
    COUNT(*) as records_processed,
    COUNT(*) as records_transformed,
    'Standardized names, regions, dates, and numeric values' as notes
FROM raw_sales_data;

-- Cleanup temporary tables
DROP TABLE IF EXISTS text_data;

/*
 * Best Practices for Data Transformation:
 * 1. Always validate data before transformation
 * 2. Preserve original data during transformation
 * 3. Log transformation activities for audit trail
 * 4. Handle NULL values appropriately
 * 5. Use consistent naming conventions
 * 6. Test transformations with sample data first
 * 7. Document transformation rules and logic
 * 8. Consider performance impact of complex transformations
 * 
 * Common Transformation Patterns:
 * - Standardization (formats, cases, values)
 * - Normalization (splitting, combining data)
 * - Aggregation (summarizing, grouping)
 * - Enrichment (adding calculated fields)
 * - Cleaning (removing, fixing invalid data)
 * - Pivoting (rows to columns, columns to rows)
 */

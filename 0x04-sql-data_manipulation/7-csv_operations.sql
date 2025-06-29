-- ================================================================
-- File: 7-csv_operations.sql
-- Description: Comprehensive CSV import/export operations
-- Author: Alpha0-1
-- ================================================================

-- Create tables for CSV operations demonstrations
CREATE TABLE IF NOT EXISTS csv_products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(255),
    category VARCHAR(100),
    price DECIMAL(10,2),
    stock_quantity INT,
    supplier_name VARCHAR(100),
    created_date DATE,
    is_active BOOLEAN DEFAULT TRUE
);

-- Create staging table for CSV imports
CREATE TABLE IF NOT EXISTS csv_staging (
    id INT AUTO_INCREMENT PRIMARY KEY,
    raw_data TEXT,
    column_1 VARCHAR(255),
    column_2 VARCHAR(255),
    column_3 VARCHAR(255),
    column_4 VARCHAR(255),
    column_5 VARCHAR(255),
    column_6 VARCHAR(255),
    column_7 VARCHAR(255),
    column_8 VARCHAR(255),
    import_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processed BOOLEAN DEFAULT FALSE
);

-- Create error log table for CSV operations
CREATE TABLE IF NOT EXISTS csv_import_errors (
    error_id INT AUTO_INCREMENT PRIMARY KEY,
    filename VARCHAR(255),
    line_number INT,
    error_message TEXT,
    raw_line TEXT,
    error_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ================================================================
-- CSV IMPORT OPERATIONS
-- ================================================================

-- Method 1: Basic CSV Import with LOAD DATA INFILE
LOAD DATA INFILE '/path/to/products.csv'
INTO TABLE csv_products
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS  -- Skip header row
(product_id, product_name, category, price, stock_quantity, supplier_name, created_date);

-- Method 2: CSV Import with data transformation
LOAD DATA INFILE '/path/to/products_raw.csv'
INTO TABLE csv_products
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(product_id, product_name, category, @price, @stock, supplier_name, @date)
SET 
    price = CASE 
        WHEN @price = '' OR @price IS NULL THEN 0.00
        WHEN @price REGEXP '^[0-9]+\.?[0-9]*$' THEN CAST(@price AS DECIMAL(10,2))
        ELSE 0.00
    END,
    stock_quantity = CASE 
        WHEN @stock = '' OR @stock IS NULL THEN 0
        WHEN @stock REGEXP '^[0-9]+$' THEN CAST(@stock AS SIGNED)
        ELSE 0
    END,
    created_date = CASE 
        WHEN @date = '' OR @date IS NULL THEN CURDATE()
        WHEN STR_TO_DATE(@date, '%Y-%m-%d') IS NOT NULL THEN STR_TO_DATE(@date, '%Y-%m-%d')
        WHEN STR_TO_DATE(@date, '%m/%d/%Y') IS NOT NULL THEN STR_TO_DATE(@date, '%m/%d/%Y')
        ELSE CURDATE()
    END;

-- Method 3: CSV Import with comprehensive error handling
DELIMITER //

CREATE PROCEDURE ImportCSVWithErrorHandling(
    IN file_path VARCHAR(255),
    IN table_name VARCHAR(100)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1
            @error_message = MESSAGE_TEXT;
        INSERT INTO csv_import_errors (filename, error_message, raw_line)
        VALUES (file_path, @error_message, 'LOAD DATA operation failed');
    END;
    
    START TRANSACTION;
    
    -- Clear staging table
    TRUNCATE TABLE csv_staging;
    
    -- Import to staging first
    SET @sql = CONCAT(
        'LOAD DATA INFILE ''', file_path, ''' ',
        'INTO TABLE csv_staging ',
        'FIELDS TERMINATED BY '','' ',
        'OPTIONALLY ENCLOSED BY ''"'' ',
        'LINES TERMINATED BY ''\n'' ',
        'IGNORE 1 ROWS ',
        '(column_1, column_2, column_3, column_4, column_5, column_6, column_7)'
    );
    
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    
    -- Process staged data
    INSERT INTO csv_products (product_id, product_name, category, price, stock_quantity, supplier_name, created_date)
    SELECT 
        CASE 
            WHEN column_1 REGEXP '^[0-9]+$' THEN CAST(column_1 AS SIGNED)
            ELSE NULL
        END,
        TRIM(column_2),
        UPPER(TRIM(column_3)),
        CASE 
            WHEN column_4 REGEXP '^[0-9]+\.?[0-9]*$' THEN CAST(column_4 AS DECIMAL(10,2))
            ELSE 0.00
        END,
        CASE 
            WHEN column_5 REGEXP '^[0-9]+$' THEN CAST(column_5 AS SIGNED)
            ELSE 0
        END,
[O        TRIM(column_6),
        CASE 
            WHEN STR_TO_DATE(column_7, '%Y-%m-%d') IS NOT NULL 
            THEN STR_TO_DATE(column_7, '%Y-%m-%d')
            ELSE CURDATE()
        END
    FROM csv_staging
    WHERE column_1 REGEXP '^[0-9]+$'
      AND TRIM(column_2) IS NOT NULL
      AND TRIM(column_2) != '';
    
    -- Log errors for invalid records
    INSERT INTO csv_import_errors (filename, line_number, error_message, raw_line)
    SELECT 
        file_path,
        id,
        'Invalid data format',
        CONCAT(column_1, ',', column_2, ',', column_3, ',', column_4, ',', column_5, ',', column_6, ',', column_7)
    FROM csv_staging
    WHERE NOT (column_1 REGEXP '^[0-9]+$'
               AND TRIM(column_2) IS NOT NULL
               AND TRIM(column_2) != '');
    
    COMMIT;
END //

DELIMITER ;

-- ================================================================
-- CSV EXPORT OPERATIONS
-- ================================================================

-- Method 1: Basic CSV Export
SELECT 
    'Product ID',
    'Product Name',
    'Category',
    'Price',
    'Stock Quantity',
    'Supplier',
    'Created Date'
UNION ALL
SELECT 
    CAST(product_id AS CHAR),
    product_name,
    category,
    CAST(price AS CHAR),
    CAST(stock_quantity AS CHAR),
    supplier_name,
    CAST(created_date AS CHAR)
FROM csv_products
WHERE is_active = TRUE
ORDER BY category, product_name
INTO OUTFILE '/tmp/products_export.csv'
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n';

-- Method 2: CSV Export with custom formatting
SELECT 
    product_id,
    CONCAT('"', REPLACE(product_name, '"', '""'), '"') as escaped_name,
    category,
    CONCAT('
    , FORMAT(price, 2)) as formatted_price,
    stock_quantity,
    CONCAT('"', REPLACE(supplier_name, '"', '""'), '"') as escaped_supplier,
    DATE_FORMAT(created_date, '%m/%d/%Y') as us_date_format
FROM csv_products
WHERE is_active = TRUE
  AND created_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
INTO OUTFILE '/tmp/recent_products.csv'
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n';

-- Method 3: CSV Export with conditional data
SELECT 
    product_id,
    product_name,
    category,
    price,
    stock_quantity,
    supplier_name,
    created_date,
    CASE 
        WHEN stock_quantity = 0 THEN 'OUT_OF_STOCK'
        WHEN stock_quantity <= 10 THEN 'LOW_STOCK'
        WHEN stock_quantity <= 50 THEN 'MEDIUM_STOCK'
        ELSE 'HIGH_STOCK'
    END as stock_status,
    CASE 
        WHEN price < 20 THEN 'BUDGET'
        WHEN price < 100 THEN 'STANDARD'
        ELSE 'PREMIUM'
    END as price_category
FROM csv_products
WHERE is_active = TRUE
ORDER BY category, stock_quantity ASC
INTO OUTFILE '/tmp/inventory_report.csv'
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n';

-- ================================================================
-- ADVANCED CSV OPERATIONS
-- ================================================================

-- Method 4: Dynamic CSV Export by Category
DELIMITER //

CREATE PROCEDURE ExportCSVByCategory()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_category VARCHAR(100);
    DECLARE v_filename VARCHAR(255);
    
    DECLARE category_cursor CURSOR FOR
        SELECT DISTINCT category 
        FROM csv_products 
        WHERE is_active = TRUE
        ORDER BY category;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    OPEN category_cursor;
    
    export_loop: LOOP
        FETCH category_cursor INTO v_category;
        
        IF done THEN
            LEAVE export_loop;
        END IF;
        
        SET v_filename = CONCAT('/tmp/products_', LOWER(REPLACE(v_category, ' ', '_')), '.csv');
        
        SET @sql = CONCAT(
            'SELECT ',
            '''Product ID'',''Product Name'',''Category'',''Price'',''Stock'',''Supplier'',''Date'' ',
            'UNION ALL ',
            'SELECT ',
            'CAST(product_id AS CHAR), ',
            'product_name, ',
            'category, ',
            'CAST(price AS CHAR), ',
            'CAST(stock_quantity AS CHAR), ',
            'supplier_name, ',
            'CAST(created_date AS CHAR) ',
            'FROM csv_products ',
            'WHERE category = ''', v_category, ''' AND is_active = TRUE ',
            'ORDER BY product_name ',
            'INTO OUTFILE ''', v_filename, ''' ',
            'FIELDS TERMINATED BY '','' ',
            'ENCLOSED BY ''"'' ',
            'LINES TERMINATED BY ''\n'''
        );
        
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
        
    END LOOP;
    
    CLOSE category_cursor;
END //

DELIMITER ;

-- Method 5: CSV Import with data validation and cleaning
DELIMITER //

CREATE PROCEDURE ProcessCSVData()
BEGIN
    DECLARE v_total_rows INT DEFAULT 0;
    DECLARE v_valid_rows INT DEFAULT 0;
    DECLARE v_error_rows INT DEFAULT 0;
    
    -- Get total rows in staging
    SELECT COUNT(*) INTO v_total_rows FROM csv_staging WHERE NOT processed;
    
    -- Process valid rows
    INSERT INTO csv_products (product_id, product_name, category, price, stock_quantity, supplier_name, created_date)
    SELECT 
        CAST(TRIM(column_1) AS SIGNED),
        TRIM(SUBSTRING(column_2, 1, 255)),
        UPPER(TRIM(SUBSTRING(column_3, 1, 100))),
        CASE 
            WHEN TRIM(column_4) REGEXP '^[0-9]+\.?[0-9]*
     
            THEN CAST(TRIM(column_4) AS DECIMAL(10,2))
            ELSE 0.00
        END,
        CASE 
            WHEN TRIM(column_5) REGEXP '^[0-9]+
     
            THEN CAST(TRIM(column_5) AS SIGNED)
            ELSE 0
        END,
        TRIM(SUBSTRING(column_6, 1, 100)),
        CASE 
            WHEN STR_TO_DATE(TRIM(column_7), '%Y-%m-%d') IS NOT NULL 
            THEN STR_TO_DATE(TRIM(column_7), '%Y-%m-%d')
            WHEN STR_TO_DATE(TRIM(column_7), '%m/%d/%Y') IS NOT NULL 
            THEN STR_TO_DATE(TRIM(column_7), '%m/%d/%Y')
            ELSE CURDATE()
        END
    FROM csv_staging
    WHERE NOT processed
      AND TRIM(column_1) REGEXP '^[0-9]+
    
      AND TRIM(column_2) IS NOT NULL
      AND TRIM(column_2) != ''
      AND LENGTH(TRIM(column_2)) >= 2
      AND TRIM(column_3) IS NOT NULL
      AND TRIM(column_3) != '';
    
    SET v_valid_rows = ROW_COUNT();
    
    -- Mark processed records
    UPDATE csv_staging 
    SET processed = TRUE 
    WHERE NOT processed
      AND TRIM(column_1) REGEXP '^[0-9]+
    
      AND TRIM(column_2) IS NOT NULL
      AND TRIM(column_2) != ''
      AND LENGTH(TRIM(column_2)) >= 2
      AND TRIM(column_3) IS NOT NULL
      AND TRIM(column_3) != '';
    
    -- Log error records
    INSERT INTO csv_import_errors (filename, line_number, error_message, raw_line)
    SELECT 
        'csv_staging_process',
        id,
        CASE 
            WHEN NOT (TRIM(column_1) REGEXP '^[0-9]+
    ) THEN 'Invalid product ID'
            WHEN TRIM(column_2) IS NULL OR TRIM(column_2) = '' THEN 'Missing product name'
            WHEN LENGTH(TRIM(column_2)) < 2 THEN 'Product name too short'
            WHEN TRIM(column_3) IS NULL OR TRIM(column_3) = '' THEN 'Missing category'
            ELSE 'Unknown validation error'
        END,
        CONCAT_WS(',', column_1, column_2, column_3, column_4, column_5, column_6, column_7)
    FROM csv_staging
    WHERE NOT processed;
    
    SET v_error_rows = ROW_COUNT();
    
    -- Output processing summary
    SELECT 
        v_total_rows as total_rows,
        v_valid_rows as valid_rows,
        v_error_rows as error_rows,
        ROUND((v_valid_rows / v_total_rows) * 100, 2) as success_rate;
        
END //

DELIMITER ;

-- ================================================================
-- CSV UTILITY FUNCTIONS
-- ================================================================

-- Function to escape CSV values
DELIMITER //

CREATE FUNCTION EscapeCSVValue(input_value TEXT) 
RETURNS TEXT
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE escaped_value TEXT;
    
    IF input_value IS NULL THEN
        RETURN '';
    END IF;
    
    SET escaped_value = REPLACE(input_value, '"', '""');
    
    -- Add quotes if value contains comma, quote, or newline
    IF LOCATE(',', escaped_value) > 0 
       OR LOCATE('"', input_value) > 0 
       OR LOCATE('\n', escaped_value) > 0 
       OR LOCATE('\r', escaped_value) > 0 THEN
        SET escaped_value = CONCAT('"', escaped_value, '"');
    END IF;
    
    RETURN escaped_value;
END //

DELIMITER ;

-- ================================================================
-- CSV BATCH PROCESSING
-- ================================================================

-- Method 6: Process large CSV files in batches
DELIMITER //

CREATE PROCEDURE ProcessLargeCSV(
    IN batch_size INT DEFAULT 1000,
    IN max_batches INT DEFAULT 100
)
BEGIN
    DECLARE v_batch_num INT DEFAULT 1;
    DECLARE v_offset INT DEFAULT 0;
    DECLARE v_processed INT DEFAULT 0;
    DECLARE v_total_unprocessed INT;
    
    -- Get count of unprocessed records
    SELECT COUNT(*) INTO v_total_unprocessed 
    FROM csv_staging 
    WHERE NOT processed;
    
    WHILE v_batch_num <= max_batches AND v_offset < v_total_unprocessed DO
        
        -- Process batch
        INSERT INTO csv_products (product_id, product_name, category, price, stock_quantity, supplier_name, created_date)
        SELECT 
            CAST(TRIM(column_1) AS SIGNED),
            TRIM(column_2),
            UPPER(TRIM(column_3)),
            CAST(TRIM(column_4) AS DECIMAL(10,2)),
            CAST(TRIM(column_5) AS SIGNED),
            TRIM(column_6),
            STR_TO_DATE(TRIM(column_7), '%Y-%m-%d')
        FROM csv_staging
        WHERE NOT processed
          AND TRIM(column_1) REGEXP '^[0-9]+
    
          AND TRIM(column_2) IS NOT NULL
          AND TRIM(column_2) != ''
        ORDER BY id
        LIMIT batch_size OFFSET v_offset;
        
        SET v_processed = ROW_COUNT();
        
        -- Mark processed records
        UPDATE csv_staging 
        SET processed = TRUE 
        WHERE id IN (
            SELECT id FROM (
                SELECT id FROM csv_staging
                WHERE NOT processed
                  AND TRIM(column_1) REGEXP '^[0-9]+
    
                  AND TRIM(column_2) IS NOT NULL
                  AND TRIM(column_2) != ''
                ORDER BY id
                LIMIT batch_size OFFSET v_offset
            ) AS batch_ids
        );
        
        SET v_offset = v_offset + batch_size;
        SET v_batch_num = v_batch_num + 1;
        
        -- Log batch progress
        INSERT INTO csv_import_errors (filename, error_message)
        VALUES ('batch_processing', 
                CONCAT('Processed batch ', v_batch_num - 1, ': ', v_processed, ' records'));
        
    END WHILE;
    
END //

DELIMITER ;

-- ================================================================
-- CSV QUALITY CONTROL
-- ================================================================

-- Create view for CSV import quality metrics
CREATE OR REPLACE VIEW csv_quality_metrics AS
SELECT 
    DATE(import_timestamp) as import_date,
    COUNT(*) as total_records,
    SUM(CASE WHEN processed THEN 1 ELSE 0 END) as processed_records,
    SUM(CASE WHEN NOT processed THEN 1 ELSE 0 END) as failed_records,
    ROUND(
        (SUM(CASE WHEN processed THEN 1 ELSE 0 END) / COUNT(*)) * 100, 
        2
    ) as success_rate_percent
FROM csv_staging
GROUP BY DATE(import_timestamp)
ORDER BY import_date DESC;

-- Procedure to generate CSV quality report
DELIMITER //

CREATE PROCEDURE GenerateCSVQualityReport()
BEGIN
    SELECT 'CSV Import Quality Report' as report_title;
    
    SELECT * FROM csv_quality_metrics;
    
    SELECT 
        'Common Error Types' as section,
        LEFT(error_message, 50) as error_type,
        COUNT(*) as error_count
    FROM csv_import_errors
    WHERE DATE(error_timestamp) = CURDATE()
    GROUP BY LEFT(error_message, 50)
    ORDER BY error_count DESC
    LIMIT 10;
    
    SELECT 
        'File Processing Summary' as section,
        filename,
        COUNT(*) as total_errors,
        COUNT(DISTINCT line_number) as affected_lines
    FROM csv_import_errors
    WHERE DATE(error_timestamp) = CURDATE()
    GROUP BY filename
    ORDER BY total_errors DESC;
    
END //

DELIMITER ;

-- ================================================================
-- USAGE EXAMPLES
-- ================================================================

-- Example 1: Import CSV with error handling
-- CALL ImportCSVWithErrorHandling('/path/to/data.csv', 'csv_products');

-- Example 2: Process staged CSV data
-- CALL ProcessCSVData();

-- Example 3: Export products by category
-- CALL ExportCSVByCategory();

-- Example 4: Generate quality report
-- CALL GenerateCSVQualityReport();

-- Example 5: Check import status
SELECT 
    COUNT(*) as total_staged,
    SUM(CASE WHEN processed THEN 1 ELSE 0 END) as processed,
    SUM(CASE WHEN NOT processed THEN 1 ELSE 0 END) as pending
FROM csv_staging;

-- Example 6: View recent errors
SELECT 
    filename,
    error_message,
    error_timestamp
FROM csv_import_errors
WHERE DATE(error_timestamp) = CURDATE()
ORDER BY error_timestamp DESC
LIMIT 10;

-- ================================================================
-- CLEANUP AND MAINTENANCE
-- ================================================================

-- Clean up old staging data
DELETE FROM csv_staging 
WHERE processed = TRUE 
  AND import_timestamp < DATE_SUB(NOW(), INTERVAL 7 DAY);

-- Archive old error logs
CREATE TABLE IF NOT EXISTS csv_import_errors_archive 
LIKE csv_import_errors;

INSERT INTO csv_import_errors_archive 
SELECT * FROM csv_import_errors 
WHERE error_timestamp < DATE_SUB(NOW(), INTERVAL 30 DAY);

DELETE FROM csv_import_errors 
WHERE error_timestamp < DATE_SUB(NOW(), INTERVAL 30 DAY);

-- ================================================================
-- Notes:
-- 1. Always validate CSV data before processing
-- 2. Use staging tables for large imports
-- 3. Implement proper error handling and logging
-- 4. Consider character encoding issues (UTF-8, etc.)
-- 5. Handle special characters and escaping properly
-- 6. Monitor file sizes and processing times
-- 7. Use batch processing for very large files
-- 8. Maintain data quality metrics and reports
-- ================================================================

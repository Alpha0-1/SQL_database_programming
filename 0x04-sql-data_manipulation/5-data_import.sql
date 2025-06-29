-- ================================================================
-- File: 5-data_import.sql
-- Description: Advanced data import techniques and methods
-- Author: Alpha0-1
-- ================================================================

-- Create sample table for import demonstrations
CREATE TABLE IF NOT EXISTS imported_products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    category VARCHAR(50),
    price DECIMAL(10,2),
    stock_quantity INT DEFAULT 0,
    import_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create staging table for data validation
CREATE TABLE IF NOT EXISTS staging_products (
    product_id INT,
    product_name VARCHAR(100),
    category VARCHAR(50),
    price DECIMAL(10,2),
    stock_quantity INT,
    source_file VARCHAR(100),
    import_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ================================================================
-- METHOD 1: LOAD DATA INFILE (MySQL specific)
-- ================================================================

-- Load data from CSV file with error handling
LOAD DATA INFILE '/path/to/products.csv'
INTO TABLE staging_products
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS  -- Skip header row
(product_id, product_name, category, price, stock_quantity)
SET source_file = 'products.csv';

-- Alternative with LOCAL keyword for client-side files
LOAD DATA LOCAL INFILE '/local/path/products.csv'
INTO TABLE staging_products
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(product_id, product_name, category, @price, @stock)
SET 
    price = CASE WHEN @price = '' THEN NULL ELSE @price END,
    stock_quantity = CASE WHEN @stock = '' THEN 0 ELSE @stock END,
    source_file = 'products.csv';

-- ================================================================
-- METHOD 2: INSERT FROM SELECT (Cross-database import)
-- ================================================================

-- Import data from another database/table
INSERT INTO imported_products (product_id, product_name, category, price, stock_quantity)
SELECT 
    id,
    name,
    category_name,
    unit_price,
    quantity_in_stock
FROM external_db.products_table
WHERE is_active = 1
  AND created_date >= DATE_SUB(NOW(), INTERVAL 30 DAY);

-- ================================================================
-- METHOD 3: Conditional Import with Data Validation
-- ================================================================

-- Import only valid data with comprehensive validation
INSERT INTO imported_products (product_id, product_name, category, price, stock_quantity)
SELECT 
    product_id,
    TRIM(product_name),
    UPPER(TRIM(category)),
    CASE 
        WHEN price <= 0 THEN NULL 
        ELSE price 
    END,
    CASE 
        WHEN stock_quantity < 0 THEN 0 
        ELSE stock_quantity 
    END
FROM staging_products
WHERE product_id IS NOT NULL
  AND TRIM(product_name) != ''
  AND LENGTH(TRIM(product_name)) >= 3
  AND (price IS NULL OR price > 0)
  AND NOT EXISTS (
      SELECT 1 FROM imported_products ip 
      WHERE ip.product_id = staging_products.product_id
  );

-- ================================================================
-- METHOD 4: Batch Import with Error Logging
-- ================================================================

-- Create error log table
CREATE TABLE IF NOT EXISTS import_errors (
    error_id INT AUTO_INCREMENT PRIMARY KEY,
    source_table VARCHAR(50),
    error_message TEXT,
    failed_record TEXT,
    error_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Batch import with error handling (MySQL procedure example)
DELIMITER //

CREATE PROCEDURE BatchImportProducts()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_product_id INT;
    DECLARE v_product_name VARCHAR(100);
    DECLARE v_category VARCHAR(50);
    DECLARE v_price DECIMAL(10,2);
    DECLARE v_stock INT;
    DECLARE v_error_msg TEXT;
    
    -- Cursor for staging data
    DECLARE product_cursor CURSOR FOR
        SELECT product_id, product_name, category, price, stock_quantity
        FROM staging_products
        WHERE product_id IS NOT NULL;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            v_error_msg = MESSAGE_TEXT;
        INSERT INTO import_errors (source_table, error_message, failed_record)
        VALUES ('staging_products', v_error_msg, 
                CONCAT('ID:', v_product_id, ' Name:', v_product_name));
    END;
    
    OPEN product_cursor;
    
    import_loop: LOOP
        FETCH product_cursor INTO v_product_id, v_product_name, v_category, v_price, v_stock;
        
        IF done THEN
            LEAVE import_loop;
        END IF;
        
        -- Attempt to insert with validation
[O        IF v_product_name IS NOT NULL AND TRIM(v_product_name) != '' THEN
            INSERT INTO imported_products (product_id, product_name, category, price, stock_quantity)
            VALUES (v_product_id, TRIM(v_product_name), UPPER(TRIM(v_category)), v_price, COALESCE(v_stock, 0))
            ON DUPLICATE KEY UPDATE
                product_name = VALUES(product_name),
                category = VALUES(category),
                price = VALUES(price),
                stock_quantity = VALUES(stock_quantity);
        END IF;
        
    END LOOP;
    
    CLOSE product_cursor;
END //

DELIMITER ;

-- ================================================================
-- METHOD 5: Incremental Import (Delta Loading)
-- ================================================================

-- Create control table for tracking imports
CREATE TABLE IF NOT EXISTS import_control (
    table_name VARCHAR(50) PRIMARY KEY,
    last_import_timestamp TIMESTAMP,
    last_import_id INT,
    records_imported INT DEFAULT 0
);

-- Incremental import based on timestamp
INSERT INTO imported_products (product_id, product_name, category, price, stock_quantity)
SELECT 
    p.product_id,
    p.product_name,
    p.category,
    p.price,
    p.stock_quantity
FROM source_products p
CROSS JOIN import_control ic
WHERE ic.table_name = 'products'
  AND p.modified_date > ic.last_import_timestamp
  AND p.product_id > ic.last_import_id
ORDER BY p.product_id;

-- Update control table
UPDATE import_control 
SET 
    last_import_timestamp = NOW(),
    last_import_id = (SELECT MAX(product_id) FROM imported_products),
    records_imported = records_imported + ROW_COUNT()
WHERE table_name = 'products';

-- ================================================================
-- METHOD 6: Import with Data Type Conversion
-- ================================================================

-- Import with explicit data type handling
INSERT INTO imported_products (product_id, product_name, category, price, stock_quantity)
SELECT 
    CAST(TRIM(col1) AS SIGNED) as product_id,
    SUBSTRING(TRIM(col2), 1, 100) as product_name,
    CASE 
        WHEN UPPER(TRIM(col3)) IN ('ELECTRONICS', 'CLOTHING', 'BOOKS', 'HOME') 
        THEN UPPER(TRIM(col3))
        ELSE 'OTHER'
    END as category,
    CASE 
        WHEN TRIM(col4) REGEXP '^[0-9]+\.?[0-9]*$' 
        THEN CAST(TRIM(col4) AS DECIMAL(10,2))
        ELSE NULL
    END as price,
    CASE 
        WHEN TRIM(col5) REGEXP '^[0-9]+$' 
        THEN CAST(TRIM(col5) AS SIGNED)
        ELSE 0
    END as stock_quantity
FROM temp_import_table
WHERE TRIM(col1) REGEXP '^[0-9]+$'  -- Ensure product_id is numeric
  AND TRIM(col2) IS NOT NULL
  AND TRIM(col2) != '';

-- ================================================================
-- Usage Examples and Best Practices
-- ================================================================

-- Example 1: Check import statistics
SELECT 
    COUNT(*) as total_imported,
    COUNT(DISTINCT category) as categories_count,
    MIN(import_date) as first_import,
    MAX(import_date) as last_import,
    AVG(price) as average_price
FROM imported_products;

-- Example 2: Validate imported data
SELECT 
    'Missing product names' as issue,
    COUNT(*) as count
FROM imported_products 
WHERE product_name IS NULL OR TRIM(product_name) = ''
UNION ALL
SELECT 
    'Invalid prices' as issue,
    COUNT(*) as count
FROM imported_products 
WHERE price <= 0 OR price IS NULL
UNION ALL
SELECT 
    'Negative stock' as issue,
    COUNT(*) as count
FROM imported_products 
WHERE stock_quantity < 0;

-- Example 3: Clean up staging tables after successful import
TRUNCATE TABLE staging_products;
DROP TABLE IF EXISTS temp_import_table;

-- ================================================================
-- Notes:
-- 1. Always use staging tables for large imports
-- 2. Implement proper error handling and logging
-- 3. Validate data before inserting into production tables
-- 4. Consider using transactions for data consistency
-- 5. Monitor performance for large datasets
-- 6. Keep track of import statistics and history
-- ================================================================

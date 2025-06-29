-- ================================================================
-- File: 6-data_export.sql
-- Description: Advanced data export methods and techniques
-- Author: Alpha0-1
-- ================================================================

-- Create sample tables for export demonstrations
CREATE TABLE IF NOT EXISTS export_products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    category VARCHAR(50),
    price DECIMAL(10,2),
    stock_quantity INT DEFAULT 0,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

-- Insert sample data for export examples
INSERT INTO export_products (product_id, product_name, category, price, stock_quantity) VALUES
(1, 'Laptop Computer', 'ELECTRONICS', 899.99, 25),
(2, 'Office Chair', 'FURNITURE', 149.99, 50),
(3, 'Programming Book', 'BOOKS', 39.99, 100),
(4, 'Wireless Mouse', 'ELECTRONICS', 29.99, 75),
(5, 'Coffee Mug', 'HOME', 12.99, 200)
ON DUPLICATE KEY UPDATE product_name = VALUES(product_name);

-- ================================================================
-- METHOD 1: SELECT INTO OUTFILE (MySQL specific)
-- ================================================================

-- Basic CSV export
SELECT 
    product_id,
    product_name,
    category,
    price,
    stock_quantity
FROM export_products
WHERE is_active = TRUE
INTO OUTFILE '/tmp/products_export.csv'
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n';

-- Export with custom formatting and headers
SELECT 'Product ID', 'Product Name', 'Category', 'Price', 'Stock'
UNION ALL
SELECT 
    CAST(product_id AS CHAR),
    product_name,
    category,
    CAST(price AS CHAR),
    CAST(stock_quantity AS CHAR)
FROM export_products
WHERE is_active = TRUE
ORDER BY category, product_name
INTO OUTFILE '/tmp/products_with_headers.csv'
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n';

-- ================================================================
-- METHOD 2: Conditional Export with Data Formatting
-- ================================================================

-- Export with calculated fields and formatting
SELECT 
    product_id as 'ID',
    UPPER(product_name) as 'PRODUCT_NAME',
    category as 'CATEGORY',
    CONCAT('$', FORMAT(price, 2)) as 'FORMATTED_PRICE',
    stock_quantity as 'STOCK',
    CASE 
        WHEN stock_quantity > 50 THEN 'High Stock'
        WHEN stock_quantity > 20 THEN 'Medium Stock'
        ELSE 'Low Stock'
    END as 'STOCK_STATUS',
    DATE_FORMAT(created_date, '%Y-%m-%d') as 'DATE_CREATED'
FROM export_products
WHERE price BETWEEN 10.00 AND 1000.00
ORDER BY category, price DESC
INTO OUTFILE '/tmp/formatted_products.csv'
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n';

-- ================================================================
-- METHOD 3: Export to Different Formats
-- ================================================================

-- Export as Tab-delimited file
SELECT 
    product_id,
    product_name,
    category,
    price,
    stock_quantity
FROM export_products
WHERE category = 'ELECTRONICS'
INTO OUTFILE '/tmp/electronics.tsv'
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\n';

-- Export as Pipe-delimited file
SELECT 
    product_id,
    product_name,
    category,
    price,
    stock_quantity
FROM export_products
WHERE stock_quantity < 30
INTO OUTFILE '/tmp/low_stock.txt'
FIELDS TERMINATED BY '|'
ENCLOSED BY ''
LINES TERMINATED BY '\n';

-- ================================================================
-- METHOD 4: Batch Export with Dynamic File Names
-- ================================================================

-- Create procedure for batch export by category
DELIMITER //

CREATE PROCEDURE ExportProductsByCategory()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_category VARCHAR(50);
    DECLARE v_filename VARCHAR(200);
    DECLARE v_sql TEXT;
    
    -- Cursor for distinct categories
    DECLARE category_cursor CURSOR FOR
        SELECT DISTINCT category 
        FROM export_products 
        WHERE is_active = TRUE
        ORDER BY category;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    OPEN category_cursor;
    
    export_loop: LOOP
        FETCH category_cursor INTO v_category;
        
        IF done THEN
            LEAVE export_loop;
        END IF;
        
        -- Create dynamic filename
        SET v_filename = CONCAT('/tmp/products_', LOWER(v_category), '_', DATE_FORMAT(NOW(), '%Y%m%d'), '.csv');
        
        -- Build dynamic SQL
        SET v_sql = CONCAT(
            'SELECT product_id, product_name, category, price, stock_quantity ',
            'FROM export_products ',
            'WHERE category = ''', v_category, ''' AND is_active = TRUE ',
            'ORDER BY product_name ',
            'INTO OUTFILE ''', v_filename, ''' ',
            'FIELDS TERMINATED BY '','' ',
            'ENCLOSED BY ''"'' ',
            'LINES TERMINATED BY ''\n'''
        );
        
        -- Execute dynamic SQL
        SET @sql = v_sql;
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
        
    END LOOP;
    
    CLOSE category_cursor;
END //

DELIMITER ;

-- ================================================================
-- METHOD 5: Export with Aggregated Data
-- ================================================================

-- Export summary report
SELECT 
    'CATEGORY_SUMMARY' as report_type,
    category as category_name,
    COUNT(*) as product_count,
    AVG(price) as average_price,
    SUM(stock_quantity) as total_stock,
    MIN(price) as min_price,
    MAX(price) as max_price
FROM export_products
WHERE is_active = TRUE
GROUP BY category
ORDER BY category
INTO OUTFILE '/tmp/category_summary.csv'
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n';

-- Export pivot-style data
SELECT 
    product_name,
    MAX(CASE WHEN category = 'ELECTRONICS' THEN price END) as electronics_price,
    MAX(CASE WHEN category = 'FURNITURE' THEN price END) as furniture_price,
    MAX(CASE WHEN category = 'BOOKS' THEN price END) as books_price,
    MAX(CASE WHEN category = 'HOME' THEN price END) as home_price
FROM export_products
WHERE is_active = TRUE
GROUP BY product_name
HAVING COUNT(DISTINCT category) > 0
INTO OUTFILE '/tmp/pivot_prices.csv'
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n';

-- ================================================================
-- METHOD 6: Incremental Export (Delta Export)
-- ================================================================

-- Create export control table
CREATE TABLE IF NOT EXISTS export_control (
    table_name VARCHAR(50) PRIMARY KEY,
    last_export_timestamp TIMESTAMP,
    last_export_id INT,
    records_exported INT DEFAULT 0
);

-- Initialize control record
INSERT INTO export_control (table_name, last_export_timestamp, last_export_id)
VALUES ('export_products', '1970-01-01 00:00:00', 0)
ON DUPLICATE KEY UPDATE table_name = table_name;

-- Incremental export (only new/modified records)
SELECT 
    ep.product_id,
    ep.product_name,
    ep.category,
    ep.price,
    ep.stock_quantity,
    ep.created_date
FROM export_products ep
CROSS JOIN export_control ec
WHERE ec.table_name = 'export_products'
  AND (ep.created_date > ec.last_export_timestamp 
       OR ep.product_id > ec.last_export_id)
  AND ep.is_active = TRUE
ORDER BY ep.product_id
INTO OUTFILE '/tmp/incremental_export.csv'
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n';

-- Update export control after successful export
UPDATE export_control 
SET 
    last_export_timestamp = NOW(),
    last_export_id = (SELECT MAX(product_id) FROM export_products),
    records_exported = records_exported + (
        SELECT COUNT(*) FROM export_products ep2
        WHERE ep2.created_date > last_export_timestamp
           OR ep2.product_id > last_export_id
    )
WHERE table_name = 'export_products';

-- ================================================================
-- METHOD 7: Export with Data Validation and Quality Checks
-- ================================================================

-- Export only validated data
SELECT 
    product_id,
    product_name,
    category,
    price,
    stock_quantity,
    'VALIDATED' as data_status
FROM export_products
WHERE is_active = TRUE
  AND product_name IS NOT NULL
  AND TRIM(product_name) != ''
  AND price > 0
  AND stock_quantity >= 0
  AND category IN ('ELECTRONICS', 'FURNITURE', 'BOOKS', 'HOME')
UNION ALL
SELECT 
    product_id,
    COALESCE(product_name, 'UNNAMED') as product_name,
    COALESCE(category, 'UNCATEGORIZED') as category,
    COALESCE(price, 0.00) as price,
    stock_quantity,
    'NEEDS_REVIEW' as data_status
FROM export_products
WHERE is_active = TRUE
  AND (product_name IS NULL 
       OR TRIM(product_name) = ''
       OR price <= 0
       OR category NOT IN ('ELECTRONICS', 'FURNITURE', 'BOOKS', 'HOME'))
ORDER BY data_status, product_id
INTO OUTFILE '/tmp/validated_export.csv'
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n';

-- ================================================================
-- METHOD 8: Export Large Datasets in Chunks
-- ================================================================

-- Create procedure for chunked export
DELIMITER //

CREATE PROCEDURE ExportInChunks(
    IN chunk_size INT DEFAULT 1000,
    IN export_path VARCHAR(255) DEFAULT '/tmp/'
)
BEGIN
    DECLARE v_offset INT DEFAULT 0;
    DECLARE v_chunk_num INT DEFAULT 1;
    DECLARE v_filename VARCHAR(300);
    DECLARE v_record_count INT;
    
    -- Get total record count
    SELECT COUNT(*) INTO v_record_count 
    FROM export_products 
    WHERE is_active = TRUE;
    
    WHILE v_offset < v_record_count DO
        -- Create chunk filename
        SET v_filename = CONCAT(export_path, 'products_chunk_', v_chunk_num, '.csv');
        
        -- Export chunk
        SET @sql = CONCAT(
            'SELECT product_id, product_name, category, price, stock_quantity ',
            'FROM export_products ',
            'WHERE is_active = TRUE ',
            'ORDER BY product_id ',
            'LIMIT ', chunk_size, ' OFFSET ', v_offset, ' ',
            'INTO OUTFILE ''', v_filename, ''' ',
            'FIELDS TERMINATED BY '','' ',
            'ENCLOSED BY ''"'' ',
            'LINES TERMINATED BY ''\n'''
        );
        
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
        
        SET v_offset = v_offset + chunk_size;
        SET v_chunk_num = v_chunk_num + 1;
    END WHILE;
    
END //

DELIMITER ;

-- ================================================================
-- Usage Examples and Monitoring
-- ================================================================

-- Example 1: Check export file existence and size (MySQL specific)
SELECT 
    'products_export.csv' as filename,
    'Check if file was created successfully' as status;

-- Example 2: Export statistics query
SELECT 
    category,
    COUNT(*) as total_products,
    COUNT(CASE WHEN price > 50 THEN 1 END) as expensive_items,
    ROUND(AVG(price), 2) as avg_price,
    SUM(stock_quantity) as total_stock
FROM export_products
WHERE is_active = TRUE
GROUP BY category
ORDER BY total_products DESC;

-- Example 3: Verify export completeness
SELECT 
    'Total records in table' as metric,
    COUNT(*) as count
FROM export_products
WHERE is_active = TRUE
UNION ALL
SELECT 
    'Records meeting export criteria' as metric,
    COUNT(*) as count
FROM export_products
WHERE is_active = TRUE
  AND product_name IS NOT NULL
  AND price > 0;

-- ================================================================
-- Cleanup procedures
-- ================================================================

-- Create procedure to clean up old export files (metadata only)
DELIMITER //

CREATE PROCEDURE CleanupExportMetadata()
BEGIN
    -- This procedure would track export metadata
    -- Actual file cleanup would be handled by system scripts
    
    CREATE TABLE IF NOT EXISTS export_log (
        export_id INT AUTO_INCREMENT PRIMARY KEY,
        filename VARCHAR(255),
        export_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        record_count INT,
        file_size_bytes BIGINT,
        status ENUM('SUCCESS', 'FAILED', 'PARTIAL')
    );
    
    -- Clean up old export logs (keep last 30 days)
    DELETE FROM export_log 
    WHERE export_date < DATE_SUB(NOW(), INTERVAL 30 DAY);
    
END //

DELIMITER ;

-- ================================================================
-- Notes:
-- 1. Ensure proper file permissions for export directories
-- 2. Monitor disk space when exporting large datasets
-- 3. Consider compression for large export files
-- 4. Implement proper error handling in production
-- 5. Use secure_file_priv settings in MySQL for security
-- 6. Consider using ETL tools for complex export requirements
-- 7. Always validate exported data before distribution
-- ================================================================

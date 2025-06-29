-- =====================================================
-- File: 5-elasticsearch_integration.sql
-- Description: Elasticsearch integration patterns with SQL
-- Author: Alpha0-1
-- =====================================================

-- Problem Statement: Implement full-text search capabilities using Elasticsearch
-- alongside traditional SQL databases for hybrid search solutions

-- =====================================================
-- 1. SQL DATABASE SETUP FOR ELASTICSEARCH SYNC
-- =====================================================

-- Main product table in SQL database
CREATE TABLE products (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    category_id INT,
    price DECIMAL(10,2),
    brand VARCHAR(100),
    status ENUM('active', 'inactive', 'discontinued') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    search_keywords TEXT, -- Additional keywords for search
    INDEX idx_category (category_id),
    INDEX idx_brand (brand),
    INDEX idx_status (status),
    INDEX idx_updated (updated_at)
);

-- Categories table
CREATE TABLE categories (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    parent_id INT,
    description TEXT,
    INDEX idx_parent (parent_id)
);

-- Product attributes for flexible metadata
CREATE TABLE product_attributes (
    id INT PRIMARY KEY AUTO_INCREMENT,
    product_id INT,
    attribute_name VARCHAR(100),
    attribute_value TEXT,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    INDEX idx_product_attr (product_id, attribute_name)
);

-- =====================================================
-- 2. ELASTICSEARCH SYNC TRACKING
-- =====================================================

-- Table to track Elasticsearch synchronization
CREATE TABLE elasticsearch_sync (
    id INT PRIMARY KEY AUTO_INCREMENT,
    table_name VARCHAR(100) NOT NULL,
    record_id INT NOT NULL,
    action ENUM('insert', 'update', 'delete') NOT NULL,
    sync_status ENUM('pending', 'completed', 'failed') DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    synced_at TIMESTAMP NULL,
    error_message TEXT,
    INDEX idx_sync_status (sync_status, created_at),
    INDEX idx_table_record (table_name, record_id)
);

-- =====================================================
-- 3. TRIGGERS FOR AUTOMATIC ELASTICSEARCH SYNC
-- =====================================================

-- Trigger for product insertions
DELIMITER //
CREATE TRIGGER product_insert_sync 
AFTER INSERT ON products
FOR EACH ROW
BEGIN
    INSERT INTO elasticsearch_sync (table_name, record_id, action)
    VALUES ('products', NEW.id, 'insert');
END//

-- Trigger for product updates
CREATE TRIGGER product_update_sync 
AFTER UPDATE ON products
FOR EACH ROW
BEGIN
    INSERT INTO elasticsearch_sync (table_name, record_id, action)
    VALUES ('products', NEW.id, 'update');
END//

-- Trigger for product deletions
CREATE TRIGGER product_delete_sync 
AFTER DELETE ON products
FOR EACH ROW
BEGIN
    INSERT INTO elasticsearch_sync (table_name, record_id, action)
    VALUES ('products', OLD.id, 'delete');
END//
DELIMITER ;

-- =====================================================
-- 4. DATA PREPARATION FOR ELASTICSEARCH
-- =====================================================

-- View to prepare product data for Elasticsearch indexing
CREATE VIEW elasticsearch_product_view AS
SELECT 
    p.id,
    p.name,
    p.description,
    p.price,
    p.brand,
    p.status,
    c.name as category_name,
    c.parent_id as parent_category_id,
    p.search_keywords,
    p.created_at,
    p.updated_at,
    -- Concatenate all searchable text
    CONCAT_WS(' ', 
        p.name, 
        p.description, 
        p.brand, 
        c.name, 
        p.search_keywords,
        GROUP_CONCAT(pa.attribute_value SEPARATOR ' ')
    ) as full_text_content,
    -- Create JSON document for Elasticsearch
    JSON_OBJECT(
        'id', p.id,
        'name', p.name,
        'description', p.description,
        'price', p.price,
        'brand', p.brand,
        'status', p.status,
        'category', JSON_OBJECT(
            'id', p.category_id,
            'name', c.name,
            'parent_id', c.parent_id
        ),
        'attributes', JSON_ARRAYAGG(
            CASE 
                WHEN pa.attribute_name IS NOT NULL 
                THEN JSON_OBJECT(pa.attribute_name, pa.attribute_value)
                ELSE NULL
            END
        ),
        'search_keywords', p.search_keywords,
        'created_at', p.created_at,
        'updated_at', p.updated_at
    ) as elasticsearch_document
FROM products p
LEFT JOIN categories c ON p.category_id = c.id
LEFT JOIN product_attributes pa ON p.id = pa.product_id
WHERE p.status = 'active'
GROUP BY p.id, p.name, p.description, p.price, p.brand, p.status, 
         c.name, c.parent_id, p.search_keywords, p.created_at, p.updated_at;

-- =====================================================
-- 5. STORED PROCEDURES FOR ELASTICSEARCH OPERATIONS
-- =====================================================

-- Procedure to get pending sync records
DELIMITER //
CREATE PROCEDURE GetPendingElasticsearchSync()
BEGIN
    SELECT 
        es.id,
        es.table_name,
        es.record_id,
        es.action,
        CASE 
            WHEN es.action = 'delete' THEN JSON_OBJECT('id', es.record_id)
            ELSE epv.elasticsearch_document
        END as document_data
    FROM elasticsearch_sync es
    LEFT JOIN elasticsearch_product_view epv ON es.record_id = epv.id
    WHERE es.sync_status = 'pending'
    ORDER BY es.created_at ASC
    LIMIT 100;
END//

-- Procedure to mark sync as completed
CREATE PROCEDURE MarkElasticsearchSyncCompleted(IN sync_id INT)
BEGIN
    UPDATE elasticsearch_sync 
    SET sync_status = 'completed', synced_at = CURRENT_TIMESTAMP
    WHERE id = sync_id;
END//

-- Procedure to mark sync as failed
CREATE PROCEDURE MarkElasticsearchSyncFailed(IN sync_id INT, IN error_msg TEXT)
BEGIN
    UPDATE elasticsearch_sync 
    SET sync_status = 'failed', error_message = error_msg
    WHERE id = sync_id;
END//
DELIMITER ;

-- =====================================================
-- 6. SEARCH INTEGRATION PATTERNS
-- =====================================================

-- Hybrid search: Get IDs from Elasticsearch, join with SQL for detailed data
-- This would be called by application layer after Elasticsearch search
DELIMITER //
CREATE PROCEDURE GetProductDetailsByIds(IN product_ids JSON)
BEGIN
    SELECT 
        p.id,
        p.name,
        p.description,
        p.price,
        p.brand,
        p.status,
        c.name as category_name,
        JSON_ARRAYAGG(
            JSON_OBJECT(
                'name', pa.attribute_name,
                'value', pa.attribute_value
            )
        ) as attributes
    FROM products p
    LEFT JOIN categories c ON p.category_id = c.id
    LEFT JOIN product_attributes pa ON p.id = pa.product_id
    WHERE p.id IN (
        SELECT JSON_UNQUOTE(JSON_EXTRACT(product_ids, CONCAT('$[', idx, ']')))
        FROM (
            SELECT 0 as idx UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 
            UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9
        ) indices
        WHERE JSON_EXTRACT(product_ids, CONCAT('$[', idx, ']')) IS NOT NULL
    )
    GROUP BY p.id, p.name, p.description, p.price, p.brand, p.status, c.name
    ORDER BY FIELD(p.id, 
        JSON_UNQUOTE(JSON_EXTRACT(product_ids, '$[0]')),
        JSON_UNQUOTE(JSON_EXTRACT(product_ids, '$[1]')),
        JSON_UNQUOTE(JSON_EXTRACT(product_ids, '$[2]')),
        JSON_UNQUOTE(JSON_EXTRACT(product_ids, '$[3]')),
        JSON_UNQUOTE(JSON_EXTRACT(product_ids, '$[4]'))
    );
END//
DELIMITER ;

-- =====================================================
-- 7. ANALYTICS AND SEARCH PERFORMANCE
-- =====================================================

-- Search analytics table
CREATE TABLE search_analytics (
    id INT PRIMARY KEY AUTO_INCREMENT,
    search_query TEXT NOT NULL,
    search_type ENUM('elasticsearch', 'sql', 'hybrid') NOT NULL,
    results_count INT,
    response_time_ms INT,
    user_id INT,
    search_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_search_type (search_type),
    INDEX idx_timestamp (search_timestamp)
);

-- Popular search terms analysis
CREATE VIEW popular_search_terms AS
SELECT 
    search_query,
    COUNT(*) as search_count,
    AVG(response_time_ms) as avg_response_time,
    AVG(results_count) as avg_results_count,
    MAX(search_timestamp) as last_searched
FROM search_analytics
WHERE search_timestamp >= DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY search_query
HAVING search_count >= 5
ORDER BY search_count DESC;

-- =====================================================
-- 8. SAMPLE DATA AND TESTING
-- =====================================================

-- Insert sample categories
INSERT INTO categories (name, description) VALUES
('Electronics', 'Electronic devices and gadgets'),
('Books', 'Books and literature'),
('Clothing', 'Apparel and accessories');

-- Insert sample products
INSERT INTO products (name, description, category_id, price, brand, search_keywords) VALUES
('iPhone 14', 'Latest Apple smartphone with advanced camera', 1, 999.99, 'Apple', 'mobile phone smartphone iOS'),
('MacBook Pro', 'High-performance laptop for professionals', 1, 2399.99, 'Apple', 'laptop computer notebook'),
('SQL Cookbook', 'Comprehensive guide to SQL programming', 2, 49.99, 'O\'Reilly', 'database programming learning'),
('Nike Air Max', 'Comfortable running shoes', 3, 129.99, 'Nike', 'shoes sneakers running sports');

-- Insert sample attributes
INSERT INTO product_attributes (product_id, attribute_name, attribute_value) VALUES
(1, 'color', 'Space Gray'),
(1, 'storage', '128GB'),
(2, 'screen_size', '14 inch'),
(2, 'memory', '16GB RAM'),
(3, 'pages', '456'),
(3, 'language', 'English'),
(4, 'size', 'US 10'),
(4, 'color', 'Black/White');

-- =====================================================
-- 9. MAINTENANCE AND MONITORING
-- =====================================================

-- Check sync queue status
SELECT 
    sync_status,
    COUNT(*) as count,
    MIN(created_at) as oldest_pending,
    MAX(created_at) as newest_pending
FROM elasticsearch_sync
GROUP BY sync_status;

-- Retry failed syncs (reset to pending)
UPDATE elasticsearch_sync 
SET sync_status = 'pending', error_message = NULL
WHERE sync_status = 'failed' 
AND created_at > DATE_SUB(NOW(), INTERVAL 1 HOUR);

-- Clean up old completed sync records
DELETE FROM elasticsearch_sync 
WHERE sync_status = 'completed' 
AND synced_at < DATE_SUB(NOW(), INTERVAL 7 DAY);

-- =====================================================
-- 10. INTEGRATION EXAMPLES
-- =====================================================

/*
Example Elasticsearch mapping (JSON):
{
  "mappings": {
    "properties": {
      "id": {"type": "integer"},
      "name": {"type": "text", "analyzer": "standard"},
      "description": {"type": "text", "analyzer": "standard"},
      "price": {"type": "float"},
      "brand": {"type": "keyword"},
      "status": {"type": "keyword"},
      "category": {
        "properties": {
          "id": {"type": "integer"},
          "name": {"type": "keyword"},
          "parent_id": {"type": "integer"}
        }
      },
      "attributes": {"type": "nested"},
      "search_keywords": {"type": "text"},
      "created_at": {"type": "date"},
      "updated_at": {"type": "date"}
    }
  }
}

Example search query (Elasticsearch):
{
  "query": {
    "bool": {
      "must": [
        {
          "multi_match": {
            "query": "smartphone apple",
            "fields": ["name^2", "description", "search_keywords"]
          }
        }
      ],
      "filter": [
        {"term": {"status": "active"}},
        {"range": {"price": {"gte": 100, "lte": 2000}}}
      ]
    }
  },
  "sort": [{"_score": {"order": "desc"}}],
  "size": 20
}
*/

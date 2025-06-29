-- =====================================================
-- File: 9-hybrid_approaches.sql
-- Description: Hybrid SQL/NoSQL approaches
-- Author: Alpha0-1
-- Purpose: Demonstrate mixing SQL and NoSQL patterns
-- =====================================================

-- Hybrid approaches combine structured and unstructured data
-- This file shows various patterns for SQL/NoSQL integration

-- 1. SQL with JSON columns (PostgreSQL example)
CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    category VARCHAR(50) NOT NULL,
    metadata JSONB,  -- NoSQL-style flexible schema
    tags TEXT[],     -- Array for tag storage
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample data with mixed structured/unstructured data
INSERT INTO products (name, price, category, metadata, tags) VALUES
('Laptop Pro', 1299.99, 'Electronics', 
 '{"brand": "TechCorp", "specs": {"ram": "16GB", "storage": "512GB SSD", "cpu": "Intel i7"}, "warranty": "2 years"}',
 ARRAY['laptop', 'premium', 'business']),
('Smartphone X', 799.99, 'Electronics',
 '{"brand": "PhoneCorp", "specs": {"screen": "6.1 inch", "camera": "12MP", "storage": "128GB"}, "color": "Space Gray"}',
 ARRAY['phone', 'mobile', 'camera']),
('Running Shoes', 129.99, 'Sports',
 '{"brand": "SportsCorp", "size_range": "7-12", "material": "mesh", "features": ["breathable", "lightweight"]}',
 ARRAY['shoes', 'running', 'fitness']);

-- 2. Query hybrid data using SQL and JSON operators
-- Find all electronics with specific specs
SELECT 
    name,
    price,
    metadata->>'brand' as brand,
    metadata->'specs'->>'ram' as ram
FROM products
WHERE category = 'Electronics'
AND metadata->'specs'->>'ram' IS NOT NULL;

-- 3. Full-text search combined with structured queries
-- Create full-text search index
CREATE INDEX IF NOT EXISTS idx_products_search 
ON products USING GIN(to_tsvector('english', name || ' ' || coalesce(metadata::text, '')));

-- Search products with text search and filters
SELECT 
    name,
    price,
    ts_rank(to_tsvector('english', name || ' ' || coalesce(metadata::text, '')), 
            plainto_tsquery('english', 'laptop intel')) as rank
FROM products
WHERE to_tsvector('english', name || ' ' || coalesce(metadata::text, '')) 
      @@ plainto_tsquery('english', 'laptop intel')
AND price BETWEEN 1000 AND 2000
ORDER BY rank DESC;

-- 4. Flexible schema evolution pattern
-- Add new fields to existing records without schema changes
UPDATE products 
SET metadata = metadata || '{"eco_friendly": true, "recycled_materials": 30}'
WHERE category = 'Sports';

-- Query for products with eco-friendly features
SELECT name, metadata->'eco_friendly' as eco_friendly
FROM products
WHERE metadata ? 'eco_friendly';

-- 5. Event sourcing pattern with SQL
CREATE TABLE IF NOT EXISTS events (
    id SERIAL PRIMARY KEY,
    aggregate_id VARCHAR(50) NOT NULL,
    event_type VARCHAR(50) NOT NULL,
    event_data JSONB NOT NULL,
    version INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert events for product lifecycle
INSERT INTO events (aggregate_id, event_type, event_data, version) VALUES
('product_1', 'ProductCreated', '{"name": "Laptop Pro", "price": 1299.99}', 1),
('product_1', 'PriceChanged', '{"old_price": 1299.99, "new_price": 1199.99}', 2),
('product_1', 'InventoryUpdated', '{"quantity": 50, "location": "warehouse_a"}', 3);

-- Rebuild current state from events
WITH product_events AS (
    SELECT 
        aggregate_id,
        event_type,
        event_data,
        version,
        ROW_NUMBER() OVER (PARTITION BY aggregate_id ORDER BY version) as rn
    FROM events
    WHERE aggregate_id = 'product_1'
)
SELECT 
    aggregate_id,
    json_agg(json_build_object(
        'event_type', event_type,
        'data', event_data,
        'version', version
    ) ORDER BY version) as event_history
FROM product_events
GROUP BY aggregate_id;

-- 6. CQRS (Command Query Responsibility Segregation) pattern
-- Write model (normalized)
CREATE TABLE IF NOT EXISTS orders (
    id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'pending'
);

CREATE TABLE IF NOT EXISTS order_items (
    id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders(id),
    product_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL,
    price DECIMAL(10,2) NOT NULL
);

-- Read model (denormalized for fast queries)
CREATE TABLE IF NOT EXISTS order_summaries (
    id SERIAL PRIMARY KEY,
    order_id INTEGER UNIQUE NOT NULL,
    customer_id INTEGER NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    item_count INTEGER NOT NULL,
    order_data JSONB NOT NULL,  -- Denormalized order details
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Function to update read model when write model changes
CREATE OR REPLACE FUNCTION update_order_summary()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO order_summaries (order_id, customer_id, total_amount, item_count, order_data)
    SELECT 
        o.id,
        o.customer_id,
        COALESCE(SUM(oi.quantity * oi.price), 0) as total_amount,
        COUNT(oi.id) as item_count,
        json_build_object(
            'order_date', o.order_date,
            'status', o.status,
            'items', json_agg(
                json_build_object(
                    'product_id', oi.product_id,
                    'quantity', oi.quantity,
                    'price', oi.price
                )
            )
        ) as order_data
    FROM orders o
    LEFT JOIN order_items oi ON o.id = oi.order_id
    WHERE o.id = COALESCE(NEW.order_id, NEW.id)
    GROUP BY o.id, o.customer_id, o.order_date, o.status
    ON CONFLICT (order_id) DO UPDATE SET
        total_amount = EXCLUDED.total_amount,
        item_count = EXCLUDED.item_count,
        order_data = EXCLUDED.order_data;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- 7. Multi-model data storage
CREATE TABLE IF NOT EXISTS content (
    id SERIAL PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    content_type VARCHAR(50) NOT NULL,
    -- Structured data
    author_id INTEGER,
    published_at TIMESTAMP,
    -- Semi-structured data
    metadata JSONB,
    -- Unstructured data
    content_body TEXT,
    -- Spatial data
    location POINT,
    -- Time series data
    metrics JSONB,
    -- Full-text search
    search_vector TSVECTOR
);

-- Insert multi-model content
INSERT INTO content (title, content_type, author_id, published_at, metadata, content_body, location, metrics) VALUES
('Tech Conference 2024', 'event', 1, '2024-06-15 09:00:00',
 '{"tags": ["technology", "conference"], "capacity": 500, "speakers": ["John Doe", "Jane Smith"]}',
 'Join us for the biggest tech conference of the year...',
 POINT(40.7128, -74.0060),  -- NYC coordinates
 '{"registrations": 450, "page_views": 15000}');

-- Update search vector
UPDATE content SET search_vector = to_tsvector('english', title || ' ' || content_body);

-- 8. Polyglot query example
-- Query combining different data types
SELECT 
    title,
    content_type,
    metadata->>'capacity' as capacity,
    location[0] as latitude,
    location[1] as longitude,
    metrics->>'registrations' as registrations,
    ts_rank(search_vector, plainto_tsquery('english', 'tech conference')) as relevance
FROM content
WHERE content_type = 'event'
AND (metadata->>'capacity')::int > 400
AND search_vector @@ plainto_tsquery('english', 'tech conference')
ORDER BY relevance DESC;

-- 9. Hybrid caching pattern
-- Cache frequently accessed data in a simplified format
CREATE TABLE IF NOT EXISTS cache_layer (
    cache_key VARCHAR(255) PRIMARY KEY,
    cache_value JSONB NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Function to get or set cache
CREATE OR REPLACE FUNCTION get_or_set_cache(
    p_key VARCHAR(255),
    p_value JSONB DEFAULT NULL,
    p_ttl_seconds INTEGER DEFAULT 3600
)
RETURNS JSONB AS $$
DECLARE
    cached_value JSONB;
BEGIN
    -- Try to get from cache
    SELECT cache_value INTO cached_value
    FROM cache_layer
    WHERE cache_key = p_key
    AND expires_at > CURRENT_TIMESTAMP;
    
    IF cached_value IS NOT NULL THEN
        RETURN cached_value;
    END IF;
    
    -- If not in cache and value provided, set it
    IF p_value IS NOT NULL THEN
        INSERT INTO cache_layer (cache_key, cache_value, expires_at)
        VALUES (p_key, p_value, CURRENT_TIMESTAMP + INTERVAL '1 second' * p_ttl_seconds)
        ON CONFLICT (cache_key) DO UPDATE SET
            cache_value = EXCLUDED.cache_value,
            expires_at = EXCLUDED.expires_at;
        
        RETURN p_value;
    END IF;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 10. Analytics on hybrid data
-- Create materialized view for analytics
CREATE MATERIALIZED VIEW IF NOT EXISTS product_analytics AS
SELECT 
    category,
    COUNT(*) as product_count,
    AVG(price) as avg_price,
    json_agg(DISTINCT metadata->>'brand') as brands,
    array_agg(DISTINCT unnest(tags)) as all_tags
FROM products
GROUP BY category;

-- Refresh materialized view
REFRESH MATERIALIZED VIEW product_analytics;

-- Query analytics
SELECT * FROM product_analytics;

-- Clean up expired cache entries
DELETE FROM cache_layer WHERE expires_at < CURRENT_TIMESTAMP;

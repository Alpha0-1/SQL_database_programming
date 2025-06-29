/*
 * File: 3-document_storage.sql
 * Description: Document storage patterns and best practices in SQL databases
 * Author: SQL Learning Team
 * Date: 2025
 * 
 * This file covers:
 * - Document storage table designs
 * - Version control for documents
 * - Document relationships and references
 * - Full-text search capabilities
 * - Document metadata management
 * - Hybrid relational-document patterns
 */

-- ============================================================================
-- BASIC DOCUMENT STORAGE STRUCTURE
-- ============================================================================

-- 1. Core document storage table
CREATE TABLE documents (
    document_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_type VARCHAR(50) NOT NULL,
    title VARCHAR(500) NOT NULL,
    content JSONB NOT NULL,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by INTEGER,
    updated_by INTEGER,
    is_active BOOLEAN DEFAULT TRUE,
    version INTEGER DEFAULT 1
);

-- 2. Document categories/collections
CREATE TABLE document_collections (
    collection_id SERIAL PRIMARY KEY,
    collection_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    schema_definition JSONB, -- Define expected document structure
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

-- 3. Document relationships (references between documents)
CREATE TABLE document_references (
    reference_id SERIAL PRIMARY KEY,
    source_document_id UUID REFERENCES documents(document_id),
    target_document_id UUID REFERENCES documents(document_id),
    reference_type VARCHAR(50) NOT NULL, -- 'link', 'embed', 'parent', 'child'
    reference_metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. Document tags for categorization
CREATE TABLE document_tags (
    tag_id SERIAL PRIMARY KEY,
    document_id UUID REFERENCES documents(document_id),
    tag_name VARCHAR(100) NOT NULL,
    tag_value VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (document_id, tag_name)
);

-- ============================================================================
-- DOCUMENT VERSIONING SYSTEM
[O-- ============================================================================

-- 5. Document version history
CREATE TABLE document_versions (
    version_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID REFERENCES documents(document_id),
    version_number INTEGER NOT NULL,
    content JSONB NOT NULL,
    metadata JSONB DEFAULT '{}',
    change_summary TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by INTEGER,
    UNIQUE(document_id, version_number)
);

-- 6. Document change log
CREATE TABLE document_change_log (
    change_id SERIAL PRIMARY KEY,
    document_id UUID REFERENCES documents(document_id),
    change_type VARCHAR(50) NOT NULL, -- 'create', 'update', 'delete', 'restore'
    field_changes JSONB, -- Track specific field changes
    old_values JSONB,
    new_values JSONB,
    changed_by INTEGER,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    change_reason TEXT
);

-- ============================================================================
-- SAMPLE DOCUMENT DATA
-- ============================================================================

-- 7. Insert document collections
INSERT INTO document_collections (collection_name, description, schema_definition) VALUES
('blog_posts', 'Blog post documents', 
 '{"required": ["title", "content", "author"], "properties": {"title": {"type": "string"}, "content": {"type": "string"}, "author": {"type": "string"}, "publish_date": {"type": "string", "format": "date"}, "tags": {"type": "array", "items": {"type": "string"}}}}'),
('product_catalogs', 'Product catalog documents',
 '{"required": ["name", "price", "category"], "properties": {"name": {"type": "string"}, "price": {"type": "number"}, "category": {"type": "string"}, "specifications": {"type": "object"}, "images": {"type": "array"}}}'),
('user_profiles', 'User profile documents',
 '{"required": ["user_id", "email"], "properties": {"user_id": {"type": "string"}, "email": {"type": "string", "format": "email"}, "personal_info": {"type": "object"}, "preferences": {"type": "object"}}}');

-- 8. Insert sample documents
INSERT INTO documents (document_type, title, content, metadata, created_by) VALUES
('blog_post', 'Getting Started with NoSQL', 
 '{"title": "Getting Started with NoSQL", "content": "NoSQL databases offer flexible schema designs that are perfect for modern applications. Unlike traditional relational databases, NoSQL systems can handle unstructured data efficiently...", "author": "John Doe", "publish_date": "2025-01-15", "tags": ["nosql", "database", "tutorial"], "word_count": 1200, "reading_time": 5}',
 '{"category": "tutorial", "difficulty": "beginner", "featured": true, "seo_keywords": ["nosql", "database design", "mongodb"]}', 1),

('product_catalog', 'Premium Wireless Headphones', 
 '{"name": "Premium Wireless Headphones", "price": 299.99, "currency": "USD", "category": "Electronics", "brand": "AudioTech", "model": "AT-WH300", "specifications": {"frequency_response": "20Hz-20kHz", "battery_life": "30 hours", "connectivity": ["Bluetooth 5.0", "3.5mm jack"], "weight": "280g", "colors": ["Black", "White", "Silver"]}, "features": ["Active Noise Cancellation", "Quick Charge", "Voice Assistant Compatible"], "images": [{"url": "/images/headphones-1.jpg", "alt": "Front view"}, {"url": "/images/headphones-2.jpg", "alt": "Side view"}], "availability": {"in_stock": true, "quantity": 150, "warehouse_locations": ["NY", "CA", "TX"]}}',
 '{"supplier": "AudioTech Corp", "cost_price": 180.00, "margin": 39.97, "last_updated": "2025-01-20", "internal_notes": "Popular item, consider bulk discount"}', 1),

('user_profile', 'User Profile - Alice Johnson',
 '{"user_id": "user_12345", "email": "alice.johnson@example.com", "personal_info": {"first_name": "Alice", "last_name": "Johnson", "date_of_birth": "1990-05-15", "location": {"city": "San Francisco", "state": "CA", "country": "USA", "timezone": "PST"}}, "preferences": {"theme": "dark", "language": "en", "notifications": {"email": true, "push": false, "sms": false}, "privacy": {"profile_public": false, "show_email": false}}, "activity": {"last_login": "2025-01-25T10:30:00Z", "login_count": 45, "account_created": "2024-03-10T14:20:00Z"}, "subscription": {"plan": "premium", "expires": "2025-12-31", "auto_renew": true}}',
 '{"account_status": "active", "verification_level": "verified", "risk_score": 0.1, "customer_segment": "high_value"}', 1);

-- ============================================================================
-- DOCUMENT QUERYING PATTERNS
-- ============================================================================

-- 9. Query documents by type and content
SELECT 
    document_id,
    title,
    content->>'author' AS author,
    content->>'publish_date' AS publish_date,
    content->'tags' AS tags
FROM documents 
WHERE document_type = 'blog_post'
  AND content->>'author' = 'John Doe';

-- 10. Search documents by nested content
SELECT 
    document_id,
    title,
    content->>'name' AS product_name,
    content->>'price' AS price,
    content->'specifications'->>'battery_life' AS battery_life
FROM documents 
WHERE document_type = 'product_catalog'
  AND (content->>'price')::DECIMAL < 500
  AND content->'specifications'->>'battery_life' IS NOT NULL;

-- 11. Complex document search with multiple conditions
SELECT 
    d.document_id,
    d.title,
    d.content->'personal_info'->>'first_name' AS first_name,
    d.content->'preferences'->>'theme' AS theme,
    d.content->'subscription'->>'plan' AS subscription_plan
FROM documents d
WHERE d.document_type = 'user_profile'
  AND d.content->'preferences'->>'theme' = 'dark'
  AND d.content->'subscription'->>'plan' = 'premium'
  AND (d.content->'activity'->>'login_count')::INTEGER > 20;

-- ============================================================================
-- DOCUMENT AGGREGATION AND ANALYTICS
-- ============================================================================

-- 12. Aggregate documents by type
SELECT 
    document_type,
    COUNT(*) AS document_count,
    AVG(LENGTH(content::TEXT)) AS avg_content_size,
    MIN(created_at) AS oldest_document,
    MAX(updated_at) AS latest_update
FROM documents 
WHERE is_active = TRUE
GROUP BY document_type;

-- 13. Analyze product catalog data
SELECT 
    content->>'category' AS category,
    COUNT(*) AS product_count,
    AVG((content->>'price')::DECIMAL) AS avg_price,
    MIN((content->>'price')::DECIMAL) AS min_price,
    MAX((content->>'price')::DECIMAL) AS max_price,
    json_agg(content->>'brand') AS brands
FROM documents 
WHERE document_type = 'product_catalog'
GROUP BY content->>'category';

-- 14. User behavior analytics
WITH user_metrics AS (
    SELECT 
        content->>'user_id' AS user_id,
        content->'personal_info'->>'location'->>'city' AS city,
        content->'subscription'->>'plan' AS plan,
        (content->'activity'->>'login_count')::INTEGER AS login_count,
        content->'preferences'->>'theme' AS theme
    FROM documents 
    WHERE document_type = 'user_profile'
)
SELECT 
    city,
    plan,
    COUNT(*) AS user_count,
    AVG(login_count) AS avg_logins,
    json_object_agg(theme, COUNT(*)) AS theme_preferences
FROM user_metrics
GROUP BY city, plan
ORDER BY user_count DESC;

-- ============================================================================
-- DOCUMENT VERSIONING OPERATIONS
-- ============================================================================

-- 15. Create a new document version
CREATE OR REPLACE FUNCTION create_document_version(
    p_document_id UUID,
    p_new_content JSONB,
    p_changed_by INTEGER,
    p_change_summary TEXT DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
    current_version INTEGER;
    new_version INTEGER;
    version_id UUID;
BEGIN
    -- Get current version
    SELECT version INTO current_version 
    FROM documents 
    WHERE document_id = p_document_id;
    
    -- Calculate new version
    new_version := current_version + 1;
    
    -- Create version record
    INSERT INTO document_versions (document_id, version_number, content, change_summary, created_by)
    VALUES (p_document_id, current_version, 
            (SELECT content FROM documents WHERE document_id = p_document_id),
            p_change_summary, p_changed_by)
    RETURNING version_id INTO version_id;
    
    -- Update main document
    UPDATE documents 
    SET content = p_new_content,
        version = new_version,
        updated_at = CURRENT_TIMESTAMP,
        updated_by = p_changed_by
    WHERE document_id = p_document_id;
    
    RETURN version_id;
END;
$$ LANGUAGE plpgsql;

-- 16. Example: Update a document with versioning
SELECT create_document_version(
    (SELECT document_id FROM documents WHERE title = 'Getting Started with NoSQL'),
    '{"title": "Getting Started with NoSQL", "content": "NoSQL databases offer flexible schema designs that are perfect for modern applications. Updated with more examples and best practices...", "author": "John Doe", "publish_date": "2025-01-15", "tags": ["nosql", "database", "tutorial", "updated"], "word_count": 1500, "reading_time": 6}',
    1,
    'Added more examples and updated content'
);

-- ============================================================================
-- DOCUMENT RELATIONSHIPS AND REFERENCES
-- ============================================================================

-- 17. Create document relationships
INSERT INTO document_references (source_document_id, target_document_id, reference_type, reference_metadata)
SELECT 
    d1.document_id,
    d2.document_id,
    'related',
    '{"relationship": "cross_reference", "strength": 0.8}'
FROM documents d1, documents d2
WHERE d1.document_type = 'blog_post' 
  AND d2.document_type = 'product_catalog'
  AND d1.document_id != d2.document_id;

-- 18. Query related documents
WITH document_network AS (
    SELECT 
        d.document_id,
        d.title,
        d.document_type,
        array_agg(
            json_build_object(
                'related_id', dr.target_document_id,
                'related_title', rd.title,
                'relationship_type', dr.reference_type
            )
        ) AS related_documents
    FROM documents d
    LEFT JOIN document_references dr ON d.document_id = dr.source_document_id
    LEFT JOIN documents rd ON dr.target_document_id = rd.document_id
    WHERE d.is_active = TRUE
    GROUP BY d.document_id, d.title, d.document_type
)
SELECT * FROM document_network
WHERE document_type = 'blog_post';

-- ============================================================================
-- FULL-TEXT SEARCH IMPLEMENTATION
-- ============================================================================

-- 19. Add full-text search column
ALTER TABLE documents ADD COLUMN search_vector tsvector;

-- 20. Create function to update search vector
CREATE OR REPLACE FUNCTION update_document_search_vector()
RETURNS TRIGGER AS $$
BEGIN
    NEW.search_vector := 
        setweight(to_tsvector('english', COALESCE(NEW.title, '')), 'A') ||
        setweight(to_tsvector('english', COALESCE(NEW.content->>'content', '')), 'B') ||
        setweight(to_tsvector('english', COALESCE(NEW.content->>'author', '')), 'C') ||
        setweight(to_tsvector('english', 
            COALESCE(array_to_string(
                ARRAY(SELECT jsonb_array_elements_text(NEW.content->'tags')), 
                ' '
            ), '')), 'D');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 21. Create trigger for automatic search vector updates
CREATE TRIGGER trigger_update_document_search_vector
    BEFORE INSERT OR UPDATE ON documents
    FOR EACH ROW EXECUTE FUNCTION update_document_search_vector();

-- 22. Update existing documents' search vectors
UPDATE documents SET updated_at = updated_at; -- Trigger the update

-- 23. Create GIN index for full-text search
CREATE INDEX idx_documents_search_vector 
ON documents USING GIN (search_vector);

-- 24. Full-text search queries
-- Basic search
SELECT 
    document_id,
    title,
    document_type,
    ts_rank(search_vector, plainto_tsquery('english', 'database tutorial')) AS relevance
FROM documents 
WHERE search_vector @@ plainto_tsquery('english', 'database tutorial')
ORDER BY relevance DESC;

-- Advanced search with ranking
SELECT 
    document_id,
    title,
    document_type,
    ts_rank_cd(search_vector, query) AS relevance,
    ts_headline('english', content->>'content', query, 'MaxWords=20, MinWords=5') AS snippet
FROM documents, plainto_tsquery('english', 'NoSQL flexible schema') AS query
WHERE search_vector @@ query
ORDER BY relevance DESC;

-- ============================================================================
-- DOCUMENT SCHEMA VALIDATION
-- ============================================================================

-- 25. Schema validation function
CREATE OR REPLACE FUNCTION validate_document_schema(
    p_document_type VARCHAR,
    p_content JSONB
) RETURNS BOOLEAN AS $$
DECLARE
    schema_def JSONB;
    required_fields TEXT[];
    field TEXT;
BEGIN
    -- Get schema definition
    SELECT schema_definition INTO schema_def
    FROM document_collections 
    WHERE collection_name = p_document_type;
    
    IF schema_def IS NULL THEN
        RETURN TRUE; -- No schema defined, allow anything
    END IF;
    
    -- Check required fields
    IF schema_def ? 'required' THEN
        required_fields := ARRAY(SELECT jsonb_array_elements_text(schema_def->'required'));
        
        FOREACH field IN ARRAY required_fields LOOP
            IF NOT (p_content ? field) THEN
                RAISE NOTICE 'Missing required field: %', field;
                RETURN FALSE;
            END IF;
        END LOOP;
    END IF;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- 26. Add schema validation constraint
ALTER TABLE documents 
ADD CONSTRAINT valid_document_schema 
CHECK (validate_document_schema(document_type, content));

-- ============================================================================
-- DOCUMENT ARCHIVAL AND LIFECYCLE MANAGEMENT
-- ============================================================================

-- 27. Document archival table
CREATE TABLE archived_documents (
    archive_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    original_document_id UUID NOT NULL,
    document_type VARCHAR(50) NOT NULL,
    title VARCHAR(500) NOT NULL,
    content JSONB NOT NULL,
    metadata JSONB DEFAULT '{}',
    archived_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    archived_by INTEGER,
    archive_reason TEXT,
    original_created_at TIMESTAMP,
    original_updated_at TIMESTAMP
);

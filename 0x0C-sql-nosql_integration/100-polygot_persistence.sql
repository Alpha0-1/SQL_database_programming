/*
 * File: 100-polyglot_persistence.sql
 * Description: Polyglot Persistence Patterns and Multi-Database Architecture
 * Author: Alpha0-1
 * 
 * This file demonstrates polyglot persistence - using multiple database
 * technologies together to leverage the strengths of each for specific use cases
 */

-- =============================================================================
-- SECTION 1: Core Relational Data (PostgreSQL/MySQL)
-- =============================================================================

/*
 * Primary relational database for ACID transactions and complex relationships
 * Handles user accounts, orders, inventory, and financial data
 */

-- User management with strong consistency requirements
CREATE TABLE users_relational (
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    account_balance DECIMAL(12,2) DEFAULT 0.00,
    
    -- Audit fields
    version INTEGER DEFAULT 1,
    is_active BOOLEAN DEFAULT true
);

-- Product catalog with referential integrity
CREATE TABLE products_relational (
    product_id SERIAL PRIMARY KEY,
    sku VARCHAR(100) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    category_id INTEGER REFERENCES categories(category_id),
    inventory_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT positive_price CHECK (price > 0),
    CONSTRAINT non_negative_inventory CHECK (inventory_count >= 0)
);

-- Order management requiring ACID properties
CREATE TABLE orders_relational (
    order_id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users_relational(user_id),
    order_status VARCHAR(50) DEFAULT 'pending',
    total_amount DECIMAL(12,2) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Ensure data integrity
    CONSTRAINT positive_amount CHECK (total_amount > 0)
);

CREATE TABLE order_items (
    order_item_id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders_relational(order_id) ON DELETE CASCADE,
    product_id INTEGER REFERENCES products_relational(product_id),
    quantity INTEGER NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    line_total DECIMAL(12,2) GENERATED ALWAYS AS (quantity * unit_price) STORED,
    
    CONSTRAINT positive_quantity CHECK (quantity > 0),
    CONSTRAINT positive_unit_price CHECK (unit_price > 0)
);

-- =============================================================================
-- SECTION 2: Document Store Integration (MongoDB-style)
-- =============================================================================

/*
 * Document storage for flexible, schema-less data
 * Using PostgreSQL JSONB to simulate MongoDB functionality
 */

-- User preferences and flexible attributes
CREATE TABLE user_profiles_document (
    profile_id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users_relational(user_id),
    profile_data JSONB NOT NULL,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Ensure user_id exists in relational table
    CONSTRAINT fk_user_exists FOREIGN KEY (user_id) REFERENCES users_relational(user_id)
);

-- Create indexes for document queries
CREATE INDEX idx_user_profiles_user_id ON user_profiles_document(user_id);
CREATE INDEX idx_user_profiles_preferences ON user_profiles_document USING GIN((profile_data->'preferences'));
CREATE INDEX idx_user_profiles_address ON user_profiles_document USING GIN((profile_data->'addresses'));

-- Product reviews and ratings (document style)
CREATE TABLE product_reviews_document (
    review_id SERIAL PRIMARY KEY,
    product_id INTEGER REFERENCES products_relational(product_id),
    user_id INTEGER REFERENCES users_relational(user_id),
    review_data JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Ensure required fields exist in JSON
    CONSTRAINT review_data_required CHECK (
        review_data ? 'rating' AND 
        review_data ? 'title' AND 
        review_data ? 'content'
    )
);

-- =============================================================================
-- SECTION 3: Key-Value Store Simulation (Redis-style)
-- =============================================================================

/*
 * Fast key-value storage for caching and session management
 * Using PostgreSQL with optimized structure
 */

-- Session storage with TTL
CREATE TABLE sessions_kv (
    session_key VARCHAR(255) PRIMARY KEY,
    session_data JSONB,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for cleanup operations
CREATE INDEX idx_sessions_expires_at ON sessions_kv(expires_at);

-- Cache table for frequently accessed data
CREATE TABLE cache_kv (
    cache_key VARCHAR(500) PRIMARY KEY,
    cache_value JSONB,
    cache_type VARCHAR(50) DEFAULT 'general',
    expires_at TIMESTAMP WITH TIME ZONE,
    hit_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_accessed TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================================================
-- SECTION 4: Time-Series Data (InfluxDB-style)
-- =============================================================================

/*
 * Time-series data for analytics and monitoring
 * Using PostgreSQL with TimescaleDB-like patterns
 */

-- User activity tracking
CREATE TABLE user_activity_timeseries (
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    user_id INTEGER NOT NULL,
    activity_type VARCHAR(100) NOT NULL,
    page_url TEXT,
    session_id VARCHAR(255),
    metrics JSONB,
    
    PRIMARY KEY (timestamp, user_id, activity_type)
);

-- Partition by time for better performance
CREATE INDEX idx_activity_timestamp ON user_activity_timeseries(timestamp DESC);
CREATE INDEX idx_activity_user_id ON user_activity_timeseries(user_id, timestamp);

-- System metrics and monitoring
CREATE TABLE system_metrics_timeseries (
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    metric_name VARCHAR(100) NOT NULL,
    metric_value DOUBLE PRECISION NOT NULL,
    tags JSONB,
    
    PRIMARY KEY (timestamp, metric_name)
);

-- =============================================================================
-- SECTION 5: Search Engine Integration (Elasticsearch-style)
-- =============================================================================

/*
 * Full-text search capabilities
 * Using PostgreSQL full-text search with document references
 */

-- Search index for products
CREATE TABLE product_search_index (
    product_id INTEGER PRIMARY KEY REFERENCES products_relational(product_id),
    search_vector tsvector,
    indexed_content TEXT,
    category_path TEXT[],
    price_range VARCHAR(50),
    last_indexed TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create full-text search index
CREATE INDEX idx_product_search_vector ON product_search_index USING GIN(search_vector);

-- Function to update search index
CREATE OR REPLACE FUNCTION update_product_search_index()
RETURNS TRIGGER AS $$
BEGIN
    -- Update or insert search index entry
    INSERT INTO product_search_index (product_id, search_vector, indexed_content)
    VALUES (
        NEW.product_id,
        to_tsvector('english', COALESCE(NEW.name, '') || ' ' || COALESCE(NEW.description, '')),
        NEW.name || ' ' || COALESCE(NEW.description, '')
    )
    ON CONFLICT (product_id) DO UPDATE SET
        search_vector = to_tsvector('english', COALESCE(NEW.name, '') || ' ' || COALESCE(NEW.description, '')),
        indexed_content = NEW.name || ' ' || COALESCE(NEW.description, ''),
        last_indexed = NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically update search index
CREATE TRIGGER update_product_search_trigger
    AFTER INSERT OR UPDATE ON products_relational
    FOR EACH ROW EXECUTE FUNCTION update_product_search_index();

-- =============================================================================
-- SECTION 6: Graph Database Simulation (Neo4j-style)
-- =============================================================================

/*
 * Graph relationships for recommendations and social features
 * Using adjacency list pattern in relational database
 */

-- User relationships (following, friends, etc.)
CREATE TABLE user_relationships_graph (
    relationship_id SERIAL PRIMARY KEY,
    from_user_id INTEGER REFERENCES users_relational(user_id),
    to_user_id INTEGER REFERENCES users_relational(user_id),
    relationship_type VARCHAR(50) NOT NULL,
    strength DECIMAL(3,2) DEFAULT 1.0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(from_user_id, to_user_id, relationship_type),
    CONSTRAINT different_users CHECK (from_user_id != to_user_id),
    CONSTRAINT valid_strength CHECK (strength BETWEEN 0.0 AND 1.0)
);

-- Product relationships (similar products, frequently bought together)
CREATE TABLE product_relationships_graph (
    relationship_id SERIAL PRIMARY KEY,
    from_product_id INTEGER REFERENCES products_relational(product_id),
    to_product_id INTEGER REFERENCES products_relational(product_id),
    relationship_type VARCHAR(50) NOT NULL,
    strength DECIMAL(5,4) DEFAULT 1.0,
    interaction_count INTEGER DEFAULT 1,
    
    UNIQUE(from_product_id, to_product_id, relationship_type),
    CONSTRAINT different_products CHECK (from_product_id != to_product_id)
);

-- =============================================================================
-- SECTION 7: Data Synchronization and Consistency
-- =============================================================================

/*
 * Patterns for maintaining consistency across different database types
 */

-- Event sourcing table for cross-database synchronization
CREATE TABLE domain_events (
    event_id SERIAL PRIMARY KEY,
    aggregate_type VARCHAR(100) NOT NULL,
    aggregate_id VARCHAR(100) NOT NULL,
    event_type VARCHAR(100) NOT NULL,
    event_data JSONB NOT NULL,
    event_version INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    processed_at TIMESTAMP WITH TIME ZONE,
    
    -- Ensure event ordering
    UNIQUE(aggregate_type, aggregate_id, event_version)
);

-- Synchronization status tracking
CREATE TABLE sync_status (
    sync_id SERIAL PRIMARY KEY,
    source_table VARCHAR(100) NOT NULL,
    target_system VARCHAR(100) NOT NULL,
    last_sync_timestamp TIMESTAMP WITH TIME ZONE,
    sync_status VARCHAR(50) DEFAULT 'pending',
    error_count INTEGER DEFAULT 0,
    last_error_message TEXT
);

-- =============================================================================
-- SECTION 8: Polyglot Query Examples
-- =============================================================================

/*
 * Complex queries that leverage multiple storage patterns
 */

-- Find users with similar preferences (document + relational)
WITH user_preferences AS (
    SELECT 
        u.user_id,
        u.username,
        upd.profile_data->'preferences' as preferences
    FROM users_relational u
    JOIN user_profiles_document upd ON u.user_id = upd.user_id
    WHERE upd.profile_data ? 'preferences'
)
SELECT 
    u1.username as user1,
    u2.username as user2,
    jsonb_object_keys(u1.preferences) as common_preferences
FROM user_preferences u1
CROSS JOIN user_preferences u2
WHERE u1.user_id < u2.user_id
  AND u1.preferences ?| array(SELECT jsonb_object_keys(u2.preferences));

-- Product recommendations using graph relationships
WITH product_recommendations AS (
    SELECT 
        prg.from_product_id,
        prg.to_product_id,
        prg.strength,
        pr.name as recommended_product,
        pr.price
    FROM product_relationships_graph prg
    JOIN products_relational pr ON prg.to_product_id = pr.product_id
    WHERE prg.relationship_type = 'frequently_bought_together'
      AND prg.strength > 0.5
)
SELECT 
    p.name as original_product,
    pr.recommended_product,
    pr.price,
    pr.strength as recommendation_strength
FROM products_relational p
JOIN product_recommendations pr ON p.product_id = pr.from_product_id
ORDER BY p.name, pr.strength DESC;

-- User activity analysis (time-series + relational)
SELECT 
    u.username,
    COUNT(*) as total_activities,
    COUNT(DISTINCT DATE(uat.timestamp)) as active_days,
    AVG(EXTRACT(EPOCH FROM (uat.timestamp - LAG(uat.timestamp) OVER (PARTITION BY u.user_id ORDER BY uat.timestamp)))) as avg_session_gap_seconds
FROM users_relational u
JOIN user_activity_timeseries uat ON u.user_id = uat.user_id
WHERE uat.timestamp >= NOW() - INTERVAL '30 days'
GROUP BY u.user_id, u.username
HAVING COUNT(*) > 10
ORDER BY total_activities DESC;

-- =============================================================================
-- SECTION 9: Maintenance and Cleanup Procedures
-- =============================================================================

/*
 * Maintenance procedures for polyglot persistence
 */

-- Clean expired sessions and cache entries
CREATE OR REPLACE FUNCTION cleanup_expired_data()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER := 0;
    temp_count INTEGER;
BEGIN
    -- Clean expired sessions
    DELETE FROM sessions_kv WHERE expires_at < NOW();
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_count := deleted_count + temp_count;
    
    -- Clean expired cache entries
    DELETE FROM cache_kv WHERE expires_at < NOW();
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_count := deleted_count + temp_count;
    
    -- Archive old activity data (older than 1 year)
    DELETE FROM user_activity_timeseries 
    WHERE timestamp < NOW() - INTERVAL '1 year';
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_count := deleted_count + temp_count;
    
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- SECTION 10: Example Data and Usage
-- =============================================================================

/*
 * Sample data insertion for testing polyglot patterns
 */

-- Insert sample users
INSERT INTO users_relational (username, email, password_hash) VALUES
('john_doe', 'john@example.com', 'hashed_password_1'),
('jane_smith', 'jane@example.com', 'hashed_password_2'),
('bob_wilson', 'bob@example.com', 'hashed_password_3');

-- Insert user profiles (document style)
INSERT INTO user_profiles_document (user_id, profile_data) VALUES
(1, '{
    "preferences": {
        "categories": ["electronics", "books"],
        "price_range": "100-500",
        "notifications": true
    },
    "addresses": [
        {
            "type": "home",
            "street": "123 Main St",
            "city": "Anytown",
            "country": "USA"
        }
    ],
    "metadata": {
        "last_login": "2024-12-01T10:00:00Z",
        "login_count": 25
    }
}'),
(2, '{
    "preferences": {
        "categories": ["clothing", "electronics"],
        "price_range": "50-200",
        "notifications": false
    },
    "addresses": [
        {
            "type": "work",
            "street": "456 Business Ave",
            "city": "Worktown",
            "country": "USA"
        }
    ]
}');

-- Insert cache data
INSERT INTO cache_kv (cache_key, cache_value, cache_type, expires_at) VALUES
('user:1:recommendations', '{"products": [101, 102, 103], "generated_at": "2024-12-01T10:00:00Z"}', 'recommendations', NOW() + INTERVAL '1 hour'),
('popular_products', '{"product_ids": [101, 105, 107, 110], "updated_at": "2024-12-01T09:00:00Z"}', 'product_list', NOW() + INTERVAL '30 minutes');

/*
 * Notes for Implementation:
 * 
 * 1. Database Selection Criteria:
 *    - Relational: ACID properties, complex relationships, financial data
 *    - Document: Flexible schema, user preferences, product catalogs
 *    - Key-Value: Caching, session management, simple lookups
 *    - Time-Series: Analytics, monitoring, activity tracking
 *    - Search: Full-text search, content discovery
 *    - Graph: Recommendations, social features, relationship analysis
 * 
 * 2. Consistency Patterns:
 *    - Strong consistency: Financial transactions, inventory
 *    - Eventual consistency: User preferences, recommendations
 *    - Session consistency: User activity, shopping carts
 * 
 * 3. Performance Considerations:
 *    - Use appropriate indexes for each access pattern
 *    - Implement caching strategies
 *    - Consider read replicas for different workloads
 *    - Monitor query performance across systems
 */

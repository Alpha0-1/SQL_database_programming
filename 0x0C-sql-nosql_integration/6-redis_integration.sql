-- =====================================================
-- File: 6-redis_integration.sql
-- Description: Redis integration patterns with SQL databases
-- Author: Alpha0-1
-- =====================================================

-- Problem Statement: Implement caching, session management, and real-time features
-- using Redis alongside SQL databases for improved performance and scalability

-- =====================================================
-- 1. SQL DATABASE SETUP FOR REDIS INTEGRATION
-- =====================================================

-- User sessions table (backup for Redis sessions)
CREATE TABLE user_sessions (
    session_id VARCHAR(128) PRIMARY KEY,
    user_id INT NOT NULL,
    session_data JSON,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_activity TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NOT NULL,
    INDEX idx_user_id (user_id),
    INDEX idx_expires (expires_at),
    INDEX idx_activity (last_activity)
);

-- Cache invalidation tracking
CREATE TABLE cache_invalidation (
    id INT PRIMARY KEY AUTO_INCREMENT,
    cache_key VARCHAR(255) NOT NULL,
    table_name VARCHAR(100),
    record_id INT,
    action ENUM('insert', 'update', 'delete') NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processed BOOLEAN DEFAULT FALSE,
    INDEX idx_processed (processed, created_at),
    INDEX idx_cache_key (cache_key)
);

-- Rate limiting table (fallback for Redis)
CREATE TABLE rate_limits (
    id VARCHAR(255) PRIMARY KEY, -- IP or user_id based
    requests_count INT DEFAULT 1,
    window_start TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_window (window_start)
);

-- =====================================================
-- 2. CORE TABLES FOR DEMONSTRATION
-- =====================================================

-- Users table
CREATE TABLE users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    profile_data JSON,
    status ENUM('active', 'inactive', 'suspended') DEFAULT 'active',
    last_login TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_username (username),
    INDEX idx_email (email),
    INDEX idx_status (status)
);

-- Products table (for caching examples)
CREATE TABLE products (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10,2),
    category_id INT,
    stock_quantity INT DEFAULT 0,
    is_featured BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_category (category_id),
    INDEX idx_featured (is_featured),
    INDEX idx_stock (stock_quantity)
);

-- Shopping cart table
CREATE TABLE shopping_carts (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    product_id INT,
    quantity INT DEFAULT 1,
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_product (user_id, product_id),
    INDEX idx_user (user_id)
);

-- =====================================================
-- 3. REDIS CACHE INVALIDATION TRIGGERS
-- =====================================================

-- Trigger for user data cache invalidation
DELIMITER //
CREATE TRIGGER user_cache_invalidation
AFTER UPDATE ON users
FOR EACH ROW
BEGIN
    -- Invalidate user profile cache
    INSERT INTO cache_invalidation (cache_key, table_name, record_id, action)
    VALUES (CONCAT('user:profile:', NEW.id), 'users', NEW.id, 'update');
    
    -- Invalidate user session cache if status changed
    IF OLD.status != NEW.status THEN
        INSERT INTO cache_invalidation (cache_key, table_name, record_id, action)
        VALUES (CONCAT('user:sessions:', NEW.id), 'users', NEW.id, 'update');
    END IF;
END//

-- Trigger for product cache invalidation
CREATE TRIGGER product_cache_invalidation
AFTER UPDATE ON products
FOR EACH ROW
BEGIN
    -- Invalidate specific product cache
    INSERT INTO cache_invalidation (cache_key, table_name, record_id, action)
    VALUES (CONCAT('product:', NEW.id), 'products', NEW.id, 'update');
    
    -- Invalidate category cache if category changed
    IF OLD.category_id != NEW.category_id THEN
        INSERT INTO cache_invalidation (cache_key, table_name, record_id, action)
        VALUES (CONCAT('category:products:', OLD.category_id), 'products', NEW.id, 'update');
        INSERT INTO cache_invalidation (cache_key, table_name, record_id, action)
        VALUES (CONCAT('category:products:', NEW.category_id), 'products', NEW.id, 'update');
    END IF;
    
    -- Invalidate featured products cache if featured status changed
    IF OLD.is_featured != NEW.is_featured THEN
        INSERT INTO cache_invalidation (cache_key, table_name, record_id, action)
        VALUES ('featured:products', 'products', NEW.id, 'update');
    END IF;
END//

-- Trigger for shopping cart cache invalidation
CREATE TRIGGER cart_cache_invalidation
AFTER INSERT ON shopping_carts
FOR EACH ROW
BEGIN
    INSERT INTO cache_invalidation (cache_key, table_name, record_id, action)
    VALUES (CONCAT('cart:', NEW.user_id), 'shopping_carts', NEW.id, 'insert');
END//

CREATE TRIGGER cart_update_cache_invalidation
AFTER UPDATE ON shopping_carts
FOR EACH ROW
BEGIN
    INSERT INTO cache_invalidation (cache_key, table_name, record_id, action)
    VALUES (CONCAT('cart:', NEW.user_id), 'shopping_carts', NEW.id, 'update');
END//

CREATE TRIGGER cart_delete_cache_invalidation
AFTER DELETE ON shopping_carts
FOR EACH ROW
BEGIN
    INSERT INTO cache_invalidation (cache_key, table_name, record_id, action)
    VALUES (CONCAT('cart:', OLD.user_id), 'shopping_carts', OLD.id, 'delete');
END//
DELIMITER ;

-- =====================================================
-- 4. STORED PROCEDURES FOR REDIS OPERATIONS
-- =====================================================

-- Get user data optimized for caching
DELIMITER //
CREATE PROCEDURE GetUserForCache(IN user_id INT)
BEGIN
    SELECT 
        id,
        username,
        email,
        profile_data,
        status,
        last_login,
        created_at,
        updated_at,
        -- Cache metadata
        UNIX_TIMESTAMP() as cached_at,
        UNIX_TIMESTAMP() + 3600 as expires_at -- 1 hour TTL
    FROM users 
    WHERE id = user_id AND status = 'active';
END//

-- Get product data for caching
CREATE PROCEDURE GetProductForCache(IN product_id INT)
BEGIN
    SELECT 
        p.id,
        p.name,
        p.description,
        p.price,
        p.category_id,
        p.stock_quantity,
        p.is_featured,
        p.updated_at,
        -- Additional computed fields for cache
        CASE 
            WHEN p.stock_quantity > 0 THEN 'in_stock'
            ELSE 'out_of_stock'
        END as availability,
        UNIX_TIMESTAMP() as cached_at,
        UNIX_TIMESTAMP() + 1800 as expires_at -- 30 minutes TTL
    FROM products p
    WHERE p.id = product_id;
END//

-- Get shopping cart for caching
CREATE PROCEDURE GetCartForCache(IN user_id INT)
BEGIN
    SELECT 
        sc.user_id,
        JSON_ARRAYAGG(
            JSON_OBJECT(
                'product_id', sc.product_id,
                'quantity', sc.quantity,
                'product_name', p.name,
                'price', p.price,
                'subtotal', sc.quantity * p.price,
                'added_at', sc.added_at
            )
        ) as cart_items,
        COUNT(sc.product_id) as item_count,
        SUM(sc.quantity * p.price) as total_amount,
        UNIX_TIMESTAMP() as cached_at,
        UNIX_TIMESTAMP() + 900 as expires_at -- 15 minutes TTL
    FROM shopping_carts sc
    JOIN products p ON sc.product_id = p.id
    WHERE sc.user_id = user_id
    GROUP BY sc.user_id;
END//

-- Session management procedure
CREATE PROCEDURE ManageUserSession(
    IN session_id VARCHAR(128),
    IN user_id INT,
    IN session_data JSON,
    IN ip_address VARCHAR(45),
    IN user_agent TEXT,
    IN expires_at TIMESTAMP
)
BEGIN
    -- Insert or update session (upsert)
    INSERT INTO user_sessions (session_id, user_id, session_data, ip_address, user_agent, expires_at)
    VALUES (session_id, user_id, session_data, ip_address, user_agent, expires_at)
    ON DUPLICATE KEY UPDATE
        session_data = VALUES(session_data),
        last_activity = CURRENT_TIMESTAMP,
        expires_at = VALUES(expires_at);
    
    -- Clean up expired sessions
    DELETE FROM user_sessions WHERE expires_at < NOW();
END//

-- Get pending cache invalidations
CREATE PROCEDURE GetPendingCacheInvalidations()
BEGIN
    SELECT 
        id,
        cache_key,
        table_name,
        record_id,
        action,
        created_at
    FROM cache_invalidation 
    WHERE processed = FALSE
    ORDER BY created_at ASC
    LIMIT 100;
END//

-- Mark cache invalidations as processed
CREATE PROCEDURE MarkCacheInvalidationsProcessed(IN invalidation_ids JSON)
BEGIN
    UPDATE cache_invalidation 
    SET processed = TRUE 
    WHERE id IN (
        SELECT JSON_UNQUOTE(JSON_EXTRACT(invalidation_ids, CONCAT('$[', idx, ']')))
        FROM (
            SELECT 0 as idx UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 
            UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9
        ) indices
        WHERE JSON_EXTRACT(invalidation_ids, CONCAT('$[', idx, ']')) IS NOT NULL
    );
END//
DELIMITER ;

-- =====================================================
-- 5. RATE LIMITING SUPPORT
-- =====================================================

-- Rate limiting check procedure
DELIMITER //
CREATE PROCEDURE CheckRateLimit(
    IN identifier VARCHAR(255),
    IN max_requests INT,
    IN window_seconds INT,
    OUT allowed BOOLEAN,
    OUT current_count INT,
    OUT reset_time TIMESTAMP
)
BEGIN
    DECLARE window_start TIMESTAMP;
    DECLARE requests_in_window INT DEFAULT 0;
    
    SET window_start = DATE_SUB(NOW(), INTERVAL window_seconds SECOND);
    
    -- Clean up old rate limit records
    DELETE FROM rate_limits WHERE window_start < window_start;
    
    -- Get current count for this identifier
    SELECT requests_count, rate_limits.window_start 
    INTO requests_in_window, reset_time
    FROM rate_limits 
    WHERE id = identifier AND rate_limits.window_start >= window_start;
    
    IF requests_in_window IS NULL THEN
        -- First request in window
        INSERT INTO rate_limits (id, requests_count, window_start)
        VALUES (identifier, 1, NOW())
        ON DUPLICATE KEY UPDATE
            requests_count = 1,
            window_start = NOW();
        
        SET allowed = TRUE;
        SET current_count = 1;
        SET reset_time = DATE_ADD(NOW(), INTERVAL window_seconds SECOND);
    ELSE
        -- Increment counter
        UPDATE rate_limits 
        SET requests_count = requests_count + 1
        WHERE id = identifier;
        
        SET current_count = requests_in_window + 1;
        SET allowed = (current_count <= max_requests);
        SET reset_time = DATE_ADD(reset_time, INTERVAL window_seconds SECOND);
    END IF;
END//
DELIMITER ;

-- =====================================================
-- 6. ANALYTICS AND MONITORING
-- =====================================================

-- Redis performance metrics table
CREATE TABLE redis_metrics (
    id INT PRIMARY KEY AUTO_INCREMENT,
    metric_name VARCHAR(100) NOT NULL,
    metric_value DECIMAL(15,4),
    metric_type ENUM('counter', 'gauge', 'histogram') DEFAULT 'gauge',
    tags JSON,
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_metric_name (metric_name),
    INDEX idx_recorded_at (recorded_at)
);

-- Cache hit/miss tracking
CREATE TABLE cache_statistics (
    id INT PRIMARY KEY AUTO_INCREMENT,
    cache_key_pattern VARCHAR(255),
    hit_count INT DEFAULT 0,
    miss_count INT DEFAULT 0,
    total_requests INT DEFAULT 0,
    avg_response_time_ms DECIMAL(10,3),
    date_recorded DATE,
    PRIMARY KEY (id),
    UNIQUE KEY unique_pattern_date (cache_key_pattern, date_recorded)
);

-- View for cache performance analysis
CREATE VIEW cache_performance_summary AS
SELECT 
    cache_key_pattern,
    SUM(hit_count) as total_hits,
    SUM(miss_count) as total_misses,
    SUM(total_requests) as total_requests,
    ROUND((SUM(hit_count) / SUM(total_requests)) * 100, 2) as hit_rate_percent,
    AVG(avg_response_time_ms) as avg_response_time,
    COUNT(DISTINCT date_recorded) as days_tracked
FROM cache_statistics
WHERE date_recorded >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY cache_key_pattern
ORDER BY hit_rate_percent DESC;

-- =====================================================
-- 7. SAMPLE DATA FOR TESTING
-- =====================================================

-- Insert sample users
INSERT INTO users (username, email, password_hash, profile_data, status) VALUES
('john_doe', 'john@example.com', 'hashed_password_1', 
 JSON_OBJECT('firstName', 'John', 'lastName', 'Doe', 'preferences', JSON_OBJECT('theme', 'dark', 'notifications', true)), 'active'),
('jane_smith', 'jane@example.com', 'hashed_password_2',
 JSON_OBJECT('firstName', 'Jane', 'lastName', 'Smith', 'preferences', JSON_OBJECT('theme', 'light', 'notifications', false)), 'active'),
('admin_user', 'admin@example.com', 'hashed_password_3',
 JSON_OBJECT('firstName', 'Admin', 'lastName', 'User', 'role', 'administrator'), 'active');

-- Insert sample products
INSERT INTO products (name, description, price, category_id, stock_quantity, is_featured) VALUES
('Wireless Headphones', 'High-quality bluetooth headphones', 99.99, 1, 50, TRUE),
('Gaming Mouse', 'Precision gaming mouse with RGB lighting', 79.99, 1, 30, FALSE),
('Ergonomic Keyboard', 'Mechanical keyboard for productivity', 149.99, 1, 25, TRUE),
('Coffee Mug', 'Ceramic coffee mug with company logo', 14.99, 2, 100, FALSE),
('T-Shirt', 'Comfortable cotton t-shirt', 24.99, 3, 75, FALSE);

-- Insert sample shopping cart items
INSERT INTO shopping_carts (user_id, product_id, quantity) VALUES
(1, 1, 1),
(1, 3, 1),
(2, 2, 2),
(2, 4, 3);

-- =====================================================
-- 8. REDIS INTEGRATION PATTERNS
-- =====================================================

/*
Redis Key Patterns and TTL Strategies:

1. User Sessions:
   Key: "session:{session_id}"
   TTL: 24 hours (86400 seconds)
   Data Type: Hash
   Example: HSET session:abc123 user_id 1 username "john_doe" last_activity 1640995200

2. User Profiles:
   Key: "user:profile:{user_id}"
   TTL: 1 hour (3600 seconds)
   Data Type: Hash or JSON String
   Example: SET user:profile:1 '{"id":1,"username":"john_doe","email":"john@example.com"}'

3. Product Cache:
   Key: "product:{product_id}"
   TTL: 30 minutes (1800 seconds)
   Data Type: Hash or JSON String
   Example: HSET product:1 name "Wireless Headphones" price 99.99 stock 50

4. Shopping Carts:
   Key: "cart:{user_id}"
   TTL: 15 minutes (900 seconds)
   Data Type: Hash or List
   Example: HSET cart:1 product:1 1 product:3 1

5. Rate Limiting:
   Key: "rate_limit:{ip_or_user_id}:{window}"
   TTL: Window duration
   Data Type: String (counter)
   Example: SET rate_limit:192.168.1.1:3600 15 EX 3600

6. Feature Flags:
   Key: "feature:{feature_name}"
   TTL: No expiration (or very long)
   Data Type: String or Hash
   Example: SET feature:new_checkout_flow "enabled"

7. Real-time Counters:
   Key: "counter:{type}:{id}"
   TTL: Based on use case
   Data Type: String (counter)
   Example: INCR counter:page_views:home

8. Leaderboards:
   Key: "leaderboard:{type}"
   TTL: Based on refresh frequency
   Data Type: Sorted Set
   Example: ZADD leaderboard:top_sellers 150 "product:1" 89 "product:2"
*/

-- =====================================================
-- 9. MAINTENANCE AND CLEANUP PROCEDURES
-- =====================================================

-- Clean up expired sessions
DELIMITER //
CREATE PROCEDURE CleanupExpiredSessions()
BEGIN
    DELETE FROM user_sessions WHERE expires_at < NOW();
    SELECT ROW_COUNT() as deleted_sessions;
END//

-- Clean up old cache invalidation records
CREATE PROCEDURE CleanupCacheInvalidations()
BEGIN
    DELETE FROM cache_invalidation 
    WHERE processed = TRUE 
    AND created_at < DATE_SUB(NOW(), INTERVAL 1 DAY);
    SELECT ROW_COUNT() as deleted_invalidations;
END//

-- Clean up old rate limit records
CREATE PROCEDURE CleanupRateLimits()
BEGIN
    DELETE FROM rate_limits 
    WHERE window_start < DATE_SUB(NOW(), INTERVAL 1 HOUR);
    SELECT ROW_COUNT() as deleted_rate_limits;
END//

-- Analyze cache performance
CREATE PROCEDURE AnalyzeCachePerformance(IN days_back INT)
BEGIN
    SELECT 
        cache_key_pattern,
        total_hits,
        total_misses,
        hit_rate_percent,
        avg_response_time,
        CASE 
            WHEN hit_rate_percent < 50 THEN 'Poor'
            WHEN hit_rate_percent < 80 THEN 'Good'
            ELSE 'Excellent'
        END as performance_rating
    FROM cache_performance_summary
    WHERE days_tracked >= days_back
    ORDER BY hit_rate_percent DESC;
END//
DELIMITER ;

-- =====================================================
-- 10. REDIS INTEGRATION EXAMPLES
-- =====================================================

/*
Application Layer Integration Examples:

1. Cache-Aside Pattern:
   - Check Redis first
   - If miss, query SQL database
   - Store result in Redis with TTL
   - Return data to client

2. Write-Through Pattern:
   - Write to SQL database
   - Immediately update Redis cache
   - Use triggers for automatic invalidation

3. Write-Behind Pattern:
   - Write to Redis immediately
   - Asynchronously write to SQL database
   - Use Redis as primary store for frequently accessed data

4. Session Management:
   - Store active sessions in Redis
   - Backup to SQL for persistence
   - Use Redis pub/sub for session events

5. Real-time Features:
   - Use Redis pub/sub for real-time notifications
   - Store temporary data in Redis
   - Aggregate to SQL for historical analysis

Example PHP Code Integration:
<?php
// Cache-aside pattern example
function getUserProfile($userId) {
    $redis = new Redis();
    $redis->connect('127.0.0.1', 6379);
    
    $cacheKey = "user:profile:{$userId}";
    $cached = $redis->get($cacheKey);
    
    if ($cached) {
        return json_decode($cached, true);
    }
    
    // Cache miss - query database
    $pdo = new PDO($dsn, $username, $password);
    $stmt = $pdo->prepare("CALL GetUserForCache(?)");
    $stmt->execute([$userId]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if ($user) {
        $redis->setex($cacheKey, 3600, json_encode($user));
    }
    
    return $user;
}
?>
*/

-- Create event to run cleanup procedures periodically
CREATE EVENT IF NOT EXISTS cleanup_redis_data
ON SCHEDULE EVERY 1 HOUR
DO
BEGIN
    CALL CleanupExpiredSessions();
    CALL CleanupCacheInvalidations();
    CALL CleanupRateLimits();
END;

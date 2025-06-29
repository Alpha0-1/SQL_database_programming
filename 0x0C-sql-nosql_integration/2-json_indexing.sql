/*
 * File: 2-json_indexing.sql
 * Description: JSON indexing strategies and performance optimization
 * Author: Alpha0-1
 * 
 * This file covers:
 * - GIN indexes for JSONB data
 * - Functional indexes on JSON expressions
 * - Partial indexes for JSON fields
 * - Index performance analysis
 * - Multi-column JSON indexes
 */

-- ============================================================================
-- BASIC JSONB INDEXING
-- ============================================================================

-- 1. GIN Index for general JSONB queries
-- This index supports containment queries (@>, <@, ?, ?&, ?|)
CREATE INDEX idx_user_profiles_gin 
ON user_profiles USING GIN (profile_data);

-- 2. GIN Index for user preferences
CREATE INDEX idx_user_preferences_gin 
ON user_profiles USING GIN (preferences);

-- 3. GIN Index for product specifications
CREATE INDEX idx_products_specs_gin 
ON products USING GIN (specifications);

-- 4. GIN Index for product pricing data
CREATE INDEX idx_products_pricing_gin 
ON products USING GIN (pricing_data);

-- ============================================================================
-- FUNCTIONAL INDEXES ON JSON EXPRESSIONS
-- ============================================================================

-- 5. Index on specific JSON field extraction
CREATE INDEX idx_user_city 
ON user_profiles ((profile_data->>'city'));

-- 6. Index on JSON numeric field with type casting
CREATE INDEX idx_user_age 
ON user_profiles (((profile_data->>'age')::INTEGER));

-- 7. Index on nested JSON field
CREATE INDEX idx_product_display_size 
ON products ((specifications->'display'->>'size'));

-- 8. Index on JSON array length
CREATE INDEX idx_user_skills_count 
ON user_profiles ((jsonb_array_length(profile_data->'skills')));

-- 9. Composite index with JSON and regular columns
CREATE INDEX idx_user_city_email 
ON user_profiles (email, (profile_data->>'city'));

-- ============================================================================
-- PARTIAL INDEXES FOR CONDITIONAL JSON QUERIES
-- ============================================================================

-- 10. Partial index for active users in specific cities
CREATE INDEX idx_active_users_major_cities 
ON user_profiles ((profile_data->>'city'))
WHERE profile_data->>'city' IN ('New York', 'San Francisco', 'Los Angeles', 'Chicago');

-- 11. Partial index for users with specific skills
CREATE INDEX idx_python_developers 
ON user_profiles USING GIN (profile_data)
WHERE profile_data->'skills' ? 'Python';

-- 12. Partial index for high-value products
CREATE INDEX idx_premium_products 
ON products USING GIN (pricing_data)
WHERE (pricing_data->>'base_price')::DECIMAL > 500;

-- 13. Partial index for products with specific features
CREATE INDEX idx_gaming_products 
ON products USING GIN (specifications)
WHERE specifications->'graphics' IS NOT NULL;

-- ============================================================================
-- ADVANCED INDEXING STRATEGIES
-- ============================================================================

-- 14. Multi-column index combining JSON and regular fields
CREATE INDEX idx_product_category_price 
ON products (category, ((pricing_data->>'base_price')::DECIMAL));

-- 15. Index for full-text search on JSON fields
CREATE INDEX idx_user_profile_fulltext 
ON user_profiles USING GIN (
    to_tsvector('english', 
        COALESCE(profile_data->>'first_name', '') || ' ' ||
        COALESCE(profile_data->>'last_name', '') || ' ' ||
        COALESCE(profile_data->>'bio', '')
    )
);

-- 16. Covering index for common JSON queries
CREATE INDEX idx_user_profile_covering 
ON user_profiles (
    username, 
    (profile_data->>'first_name'),
    (profile_data->>'last_name'),
    (profile_data->>'city')
);

-- 17. Hash index for exact JSON field matches (PostgreSQL 10+)
CREATE INDEX idx_user_theme_hash 
ON user_profiles USING HASH ((preferences->>'theme'));

-- ============================================================================
-- INDEX PERFORMANCE TESTING AND ANALYSIS
-- ============================================================================

-- 18. Test query performance without indexes
-- First, let's create a larger dataset for meaningful performance testing
INSERT INTO user_profiles (username, email, profile_data, preferences)
SELECT 
    'user_' || generate_series AS username,
    'user_' || generate_series || '@example.com' AS email,
    json_build_object(
        'first_name', 'User',
        'last_name', 'Number' || generate_series,
        'age', 20 + (generate_series % 50),
        'city', CASE (generate_series % 10)
            WHEN 0 THEN 'New York'
            WHEN 1 THEN 'San Francisco'
            WHEN 2 THEN 'Los Angeles'
            WHEN 3 THEN 'Chicago'
            WHEN 4 THEN 'Boston'
            WHEN 5 THEN 'Seattle'
            WHEN 6 THEN 'Austin'
            WHEN 7 THEN 'Denver'
            WHEN 8 THEN 'Miami'
            ELSE 'Portland'
        END,
        'skills', json_build_array(
            CASE (generate_series % 5) 
                WHEN 0 THEN 'Python'
                WHEN 1 THEN 'Java'
                WHEN 2 THEN 'JavaScript'
                WHEN 3 THEN 'C++'
                ELSE 'Ruby'
            END,
            'SQL'
        ),
        'bio', 'Generated user profile for testing'
    ) AS profile_data,
    json_build_object(
        'theme', CASE (generate_series % 3)
            WHEN 0 THEN 'dark'
            WHEN 1 THEN 'light'
            ELSE 'auto'
        END,
        'notifications', json_build_object(
            'email', (generate_series % 2) = 0,
            'push', (generate_series % 3) = 0
        )
    )::jsonb AS preferences
FROM generate_series(1000, 9999);

-- 19. Performance comparison queries
-- Query 1: Search by city (should use idx_user_city)
EXPLAIN (ANALYZE, BUFFERS) 
SELECT username, profile_data->>'first_name', profile_data->>'city'
FROM user_profiles 
WHERE profile_data->>'city' = 'New York';

-- Query 2: Search by age range (should use idx_user_age)
EXPLAIN (ANALYZE, BUFFERS)
SELECT username, profile_data->>'first_name', (profile_data->>'age')::INTEGER as age
FROM user_profiles 
WHERE (profile_data->>'age')::INTEGER BETWEEN 25 AND 35;

-- Query 3: Search with JSON containment (should use GIN index)
EXPLAIN (ANALYZE, BUFFERS)
SELECT username, profile_data->'skills'
FROM user_profiles 
WHERE profile_data->'skills' ? 'Python';

-- Query 4: Complex multi-condition query
EXPLAIN (ANALYZE, BUFFERS)
SELECT username, profile_data->>'city', profile_data->'skills'
FROM user_profiles 
WHERE profile_data->>'city' = 'San Francisco'
  AND profile_data->'skills' ? 'JavaScript'
  AND (profile_data->>'age')::INTEGER > 30;

-- ============================================================================
-- INDEX MAINTENANCE AND STATISTICS
-- ============================================================================

-- 20. Check index usage statistics
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes 
WHERE schemaname = 'public' 
  AND tablename IN ('user_profiles', 'products', 'event_logs')
ORDER BY idx_scan DESC;

-- 21. Check index sizes
SELECT 
    schemaname,
    tablename,
    indexname,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes 
WHERE schemaname = 'public'
  AND tablename IN ('user_profiles', 'products', 'event_logs')
ORDER BY pg_relation_size(indexrelid) DESC;

-- 22. Analyze table statistics for query planner
ANALYZE user_profiles;
ANALYZE products;
ANALYZE event_logs;

-- ============================================================================
-- SPECIALIZED JSON INDEXING PATTERNS
-- ============================================================================

-- 23. Expression index for JSON key existence
CREATE INDEX idx_user_has_bio 
ON user_profiles ((profile_data ? 'bio'))
WHERE profile_data ? 'bio';

-- 24. Index for JSON array element queries
CREATE INDEX idx_products_port_types 
ON products USING GIN ((specifications->'ports'))
WHERE specifications->'ports' IS NOT NULL;

-- 25. Trigram index for JSON text search
CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE INDEX idx_user_bio_trigram 
ON user_profiles USING GIN ((profile_data->>'bio') gin_trgm_ops)
WHERE profile_data->>'bio' IS NOT NULL;

-- 26. Index for JSON date/timestamp fields
-- First, add some timestamp data
UPDATE user_profiles 
SET profile_data = profile_data || 
    json_build_object('last_login', NOW() - (RANDOM() * INTERVAL '30 days'))::jsonb
WHERE id <= 100;

-- Create index for date queries
CREATE INDEX idx_user_last_login 
ON user_profiles (((profile_data->>'last_login')::TIMESTAMP))
WHERE profile_data->>'last_login' IS NOT NULL;

-- ============================================================================
-- INDEX OPTIMIZATION STRATEGIES
-- ============================================================================

-- 27. Identify missing indexes using pg_stat_statements
-- This requires pg_stat_statements extension
/*
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Query to find frequently executed queries that might benefit from indexes
SELECT 
    query,
    calls,
    total_time,
    mean_time,
    rows
FROM pg_stat_statements 
WHERE query ILIKE '%profile_data%' 
   OR query ILIKE '%specifications%'
   OR query ILIKE '%preferences%'
ORDER BY calls DESC
LIMIT 10;
*/

-- 28. Index recommendations based on query patterns
WITH query_patterns AS (
    SELECT 
        'City searches' AS pattern_type,
        'CREATE INDEX idx_optimized_city ON user_profiles ((profile_data->>''city''), username);' AS recommendation,
        'Optimize frequent city-based user lookups' AS purpose
    UNION ALL
    SELECT 
        'Skill filtering',
        'CREATE INDEX idx_optimized_skills ON user_profiles USING GIN ((profile_data->''skills'')) WHERE jsonb_array_length(profile_data->''skills'') > 0;',
        'Optimize skill-based filtering with non-empty constraint'
    UNION ALL
    SELECT 
        'Product price range',
        'CREATE INDEX idx_optimized_price_range ON products (category, ((pricing_data->>''base_price'')::DECIMAL)) WHERE is_active = true;',
        'Optimize active product price range queries by category'
)
SELECT * FROM query_patterns;

-- ============================================================================
-- INDEX MONITORING AND HEALTH CHECKS
-- ============================================================================

-- 29. Monitor index bloat and fragmentation
SELECT 
    schemaname,
    tablename,
    indexname,
    pg_size_pretty(pg_relation_size(indexrelid)) as size,
    CASE 
        WHEN idx_scan = 0 THEN 'Never used'
        WHEN idx_scan < 100 THEN 'Rarely used'
        WHEN idx_scan < 1000 THEN 'Moderately used'
        ELSE 'Frequently used'
    END as usage_category,
    idx_scan as scan_count
FROM pg_stat_user_indexes 
WHERE schemaname = 'public'
ORDER BY pg_relation_size(indexrelid) DESC;

-- 30. Check for unused indexes (candidates for removal)
SELECT 
    schemaname,
    tablename,
    indexname,
    pg_size_pretty(pg_relation_size(indexrelid)) as wasted_space
FROM pg_stat_user_indexes 
WHERE idx_scan = 0 
  AND schemaname = 'public'
  AND indexname NOT LIKE '%_pkey'  -- Exclude primary key indexes
ORDER BY pg_relation_size(indexrelid) DESC;

-- ============================================================================
-- INDEX BEST PRACTICES EXAMPLES
-- ============================================================================

-- 31. Demonstrate proper index selection strategy
-- Good: Selective index for common query pattern
CREATE INDEX idx_active_python_devs_in_major_cities 
ON user_profiles USING GIN (profile_data)
WHERE profile_data->>'city' IN ('New York', 'San Francisco', 'Los Angeles')
  AND profile_data->'skills' ? 'Python';

-- 32. Composite functional index for complex queries
CREATE INDEX idx_user_profile_composite 
ON user_profiles (
    (profile_data->>'city'),
    ((profile_data->>'age')::INTEGER),
    email
) WHERE (profile_data->>'age')::INTEGER >= 18;

-- 33. Index for JSON aggregation queries
CREATE INDEX idx_city_age_aggregation 
ON user_profiles ((profile_data->>'city'), ((profile_data->>'age')::INTEGER))
WHERE profile_data->>'city' IS NOT NULL 
  AND profile_data->>'age' IS NOT NULL;

-- ============================================================================
-- PERFORMANCE TESTING SUITE
-- ============================================================================

-- 34. Benchmark different indexing approaches
DO $
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    execution_time INTERVAL;
BEGIN
    -- Test 1: Query with GIN index
    start_time := clock_timestamp();
    PERFORM COUNT(*) FROM user_profiles WHERE profile_data->'skills' ? 'Python';
    end_time := clock_timestamp();
    execution_time := end_time - start_time;
    RAISE NOTICE 'GIN index query time: %', execution_time;
    
    -- Test 2: Query with functional index
    start_time := clock_timestamp();
    PERFORM COUNT(*) FROM user_profiles WHERE profile_data->>'city' = 'New York';
    end_time := clock_timestamp();
    execution_time := end_time - start_time;
    RAISE NOTICE 'Functional index query time: %', execution_time;
    
    -- Test 3: Complex query using multiple indexes
    start_time := clock_timestamp();
    PERFORM COUNT(*) FROM user_profiles 
    WHERE profile_data->>'city' = 'San Francisco'
      AND profile_data->'skills' ? 'JavaScript'
      AND (profile_data->>'age')::INTEGER > 25;
    end_time := clock_timestamp();
    execution_time := end_time - start_time;
    RAISE NOTICE 'Multi-index query time: %', execution_time;
END $;

-- ============================================================================
-- CLEANUP AND MAINTENANCE
-- ============================================================================

-- 35. Index maintenance operations
-- Rebuild indexes if needed (usually not necessary in PostgreSQL)
-- REINDEX INDEX idx_user_profiles_gin;

-- Update statistics after major data changes
-- ANALYZE user_profiles;

-- 36. Drop unused or redundant indexes
-- DROP INDEX IF EXISTS idx_redundant_example;

/*
 * LEARNING NOTES:
 * 
 * 1. JSON Index Types:
 *    - GIN: Best for containment queries (@>, ?, ?&, ?|)
 *    - B-tree: Good for specific field extractions and ranges
 *    - Hash: Efficient for exact matches only
[O *    - GiST: Alternative to GIN, generally slower but uses less space
 * 
 * 2. Index Selection Guidelines:
 *    - Use GIN indexes for general JSONB querying
 *    - Create functional indexes for frequently accessed JSON paths
 *    - Consider partial indexes for subset queries
 *    - Monitor index usage and remove unused indexes
 * 
 * 3. Performance Considerations:
 *    - JSON indexes can be large - monitor disk space
 *    - GIN indexes speed up reads but slow down writes
 *    - Functional indexes must match exact expressions
 *    - Use EXPLAIN ANALYZE to verify index usage
 * 
 * 4. Best Practices:
 *    - Create indexes based on actual query patterns
 *    - Use partial indexes to reduce size and improve specificity
 *    - Regularly analyze tables after bulk changes
 *    - Monitor index usage statistics
 *    - Consider covering indexes for frequently accessed combinations
 */

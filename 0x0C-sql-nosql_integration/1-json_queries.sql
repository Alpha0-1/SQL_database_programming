/*
 * File: 1-json_queries.sql
 * Description: Advanced JSON querying techniques and patterns
 * Author: Alpha0-1
 * 
 * This file covers:
 * - Complex JSON path expressions
 * - JSON search and filtering
 * - JSON aggregations and analytics
 * - Cross-database JSON query patterns
 */

-- ============================================================================
-- SETUP: Using tables from previous file
-- ============================================================================

-- Ensure we have the tables from 0-json_in_sql.sql
-- This section shows sample data structure for reference

/*
Sample data structure:
user_profiles: id, username, email, profile_data (JSON), preferences (JSONB)
products: product_id, name, specifications (JSON), pricing_data (JSONB)
event_logs: log_id, event_type, event_data (JSON), user_id
*/

-- ============================================================================
-- BASIC JSON PATH QUERIES
-- ============================================================================

-- 1. Simple field extraction
SELECT 
    username,
    profile_data->>'first_name' AS first_name,
    profile_data->>'last_name' AS last_name,
    profile_data->>'city' AS city
FROM user_profiles;

-- 2. Nested field extraction
SELECT 
    name AS product_name,
    specifications->'display'->>'size' AS screen_size,
    specifications->'display'->>'resolution' AS resolution,
    specifications->'display'->>'refresh_rate' AS refresh_rate
FROM products
WHERE specifications->'display' IS NOT NULL;

-- 3. Array element access
SELECT 
    name AS product_name,
    specifications->'ports'->0 AS first_port,
    specifications->'ports'->1 AS second_port,
    jsonb_array_length(specifications->'ports') AS total_ports
FROM products
WHERE specifications->'ports' IS NOT NULL;

-- ============================================================================
-- JSON SEARCH AND FILTERING
-- ============================================================================

-- 4. Search for specific values in JSON fields
SELECT username, profile_data->>'city' AS city
FROM user_profiles
WHERE profile_data->>'city' = 'New York';

-- 5. Numeric comparisons with JSON data
SELECT 
    username,
    profile_data->>'first_name' AS name,
    (profile_data->>'age')::INTEGER AS age
FROM user_profiles
WHERE (profile_data->>'age')::INTEGER > 30;

-- 6. String pattern matching in JSON
SELECT 
    username,
    profile_data->>'bio' AS bio
FROM user_profiles
WHERE profile_data->>'bio' ILIKE '%developer%';

-- 7. JSON array containment (PostgreSQL JSONB)
SELECT 
    username,
    profile_data->'skills' AS skills
FROM user_profiles
WHERE profile_data->'skills' ? 'Python';

-- 8. Multiple array element search
SELECT 
    username,
    profile_data->'skills' AS skills
FROM user_profiles
WHERE profile_data->'skills' ?& array['Python', 'SQL'];

-- 9. Any array element search
SELECT 
    username,
    profile_data->'skills' AS skills
FROM user_profiles
WHERE profile_data->'skills' ?| array['Java', 'JavaScript', 'Python'];

-- ============================================================================
-- ADVANCED JSON PATH EXPRESSIONS
-- ============================================================================

-- 10. Complex nested queries with null handling
SELECT 
    name,
    COALESCE(
        specifications->'display'->>'size', 
        'Size not specified'
    ) AS display_size,
    CASE 
        WHEN specifications->'display'->>'refresh_rate' IS NOT NULL 
        THEN specifications->'display'->>'refresh_rate' || ' Hz'
        ELSE 'Standard refresh rate'
    END AS refresh_rate_display
FROM products;

-- 11. JSON path with array index bounds checking
SELECT 
    name,
    CASE 
        WHEN jsonb_array_length(specifications->'ports') > 0 
        THEN specifications->'ports'->0
        ELSE '"No ports available"'::jsonb
    END AS primary_port
FROM products;

-- 12. Dynamic JSON key access using variables
-- This example shows how to query JSON with dynamic keys
WITH dynamic_keys AS (
    SELECT 'first_name' AS key_name
    UNION ALL
    SELECT 'last_name'
    UNION ALL
    SELECT 'city'
)
SELECT 
    u.username,
    dk.key_name,
    u.profile_data->>dk.key_name AS field_value
FROM user_profiles u
CROSS JOIN dynamic_keys dk
WHERE u.profile_data->>dk.key_name IS NOT NULL
ORDER BY u.username, dk.key_name;

-- ============================================================================
-- JSON AGGREGATIONS AND ANALYTICS
-- ============================================================================

-- 13. Group by JSON field values
SELECT 
    profile_data->>'city' AS city,
    COUNT(*) AS user_count,
    AVG((profile_data->>'age')::INTEGER) AS avg_age,
    string_agg(profile_data->>'first_name', ', ') AS user_names
FROM user_profiles
GROUP BY profile_data->>'city'
ORDER BY user_count DESC;

-- 14. JSON array aggregation
SELECT 
    profile_data->>'city' AS city,
    json_agg(DISTINCT profile_data->>'first_name') AS users_in_city,
    json_agg(profile_data->'skills') AS all_skills_in_city
FROM user_profiles
GROUP BY profile_data->>'city';

-- 15. Complex aggregation with JSON array expansion
WITH skill_breakdown AS (
    SELECT 
        username,
        profile_data->>'city' AS city,
        jsonb_array_elements_text(profile_data->'skills') AS skill
    FROM user_profiles
    WHERE profile_data->'skills' IS NOT NULL
)
SELECT 
    city,
    skill,
    COUNT(*) AS skill_count,
    json_agg(username) AS users_with_skill
FROM skill_breakdown
GROUP BY city, skill
ORDER BY city, skill_count DESC;

-- ============================================================================
-- JSON STATISTICAL ANALYSIS
-- ============================================================================

-- 16. Statistical analysis of JSON numeric data
SELECT 
    'Age Statistics' AS metric_type,
    MIN((profile_data->>'age')::INTEGER) AS min_age,
    MAX((profile_data->>'age')::INTEGER) AS max_age,
    AVG((profile_data->>'age')::INTEGER) AS avg_age,
    STDDEV((profile_data->>'age')::INTEGER) AS age_stddev,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY (profile_data->>'age')::INTEGER) AS median_age
FROM user_profiles;

-- 17. Price analysis from JSON data
SELECT 
    category,
    COUNT(*) AS product_count,
    MIN((pricing_data->>'base_price')::DECIMAL) AS min_price,
    MAX((pricing_data->>'base_price')::DECIMAL) AS max_price,
    AVG((pricing_data->>'base_price')::DECIMAL) AS avg_price,
    SUM((pricing_data->>'base_price')::DECIMAL) AS total_value
FROM products
GROUP BY category;

-- ============================================================================
-- JSON SEARCH WITH FULL-TEXT CAPABILITIES
-- ============================================================================

-- 18. Full-text search across JSON fields
SELECT 
    username,
    profile_data->>'first_name' || ' ' || profile_data->>'last_name' AS full_name,
    profile_data->>'bio' AS bio,
    ts_rank(
        to_tsvector('english', profile_data->>'first_name' || ' ' || 
                   profile_data->>'last_name' || ' ' || 
                   COALESCE(profile_data->>'bio', '')),
        plainto_tsquery('english', 'developer')
    ) AS relevance_score
FROM user_profiles
WHERE to_tsvector('english', profile_data->>'first_name' || ' ' || 
                 profile_data->>'last_name' || ' ' || 
                 COALESCE(profile_data->>'bio', '')) @@ 
      plainto_tsquery('english', 'developer')
ORDER BY relevance_score DESC;

-- ============================================================================
-- COMPLEX JSON FILTERING AND TRANSFORMATIONS
-- ============================================================================

-- 19. Multi-condition JSON filtering
SELECT 
    username,
    profile_data->>'first_name' AS name,
    profile_data->>'city' AS city,
    profile_data->'skills' AS skills
FROM user_profiles
WHERE (profile_data->>'age')::INTEGER BETWEEN 25 AND 35
  AND profile_data->>'city' IN ('New York', 'San Francisco', 'Austin')
  AND profile_data->'skills' ? 'Python'
  AND jsonb_array_length(profile_data->'skills') >= 3;

-- 20. JSON data transformation and restructuring
SELECT 
    username,
    json_build_object(
        'personal_info', json_build_object(
            'name', profile_data->>'first_name' || ' ' || profile_data->>'last_name',
            'age', (profile_data->>'age')::INTEGER,
            'location', profile_data->>'city'
        ),
        'professional_info', json_build_object(
            'skills', profile_data->'skills',
            'bio', profile_data->>'bio',
            'skill_count', jsonb_array_length(profile_data->'skills')
        ),
        'settings', json_build_object(
            'theme', preferences->>'theme',
            'notifications_enabled', preferences->'notifications'->>'email'
        )
    ) AS restructured_profile
FROM user_profiles;

-- ============================================================================
-- JSON QUERIES FOR ANALYTICS AND REPORTING
-- ============================================================================

-- 21. User engagement analytics from event logs
SELECT 
    event_type,
    COUNT(*) AS event_count,
    COUNT(DISTINCT user_id) AS unique_users,
    json_object_agg(
        DATE(timestamp_occurred), 
        COUNT(*)
    ) AS daily_breakdown
FROM event_logs
WHERE timestamp_occurred >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY event_type
ORDER BY event_count DESC;

-- 22. Product recommendation based on JSON data
WITH user_preferences AS (
    SELECT 
        username,
        profile_data->'skills' AS skills,
        preferences->>'theme' AS theme_preference
    FROM user_profiles
),
product_matching AS (
    SELECT 
        p.name,
        p.specifications,
        p.pricing_data->>'base_price' AS price,
        up.username,
        CASE 
            WHEN up.theme_preference = 'dark' AND p.specifications->'colors' ? 'Black' THEN 5
            WHEN up.theme_preference = 'light' AND p.specifications->'colors' ? 'White' THEN 5
            ELSE 0
        END +
        CASE 
            WHEN up.skills ? 'Python' AND p.category = 'Electronics' THEN 10
            WHEN up.skills ? 'Java' AND p.category = 'Electronics' THEN 8
            ELSE 0
        END AS recommendation_score
    FROM products p
    CROSS JOIN user_preferences up
    WHERE p.is_active = TRUE
)
SELECT 
    username,
    name AS recommended_product,
    price,
    recommendation_score
FROM product_matching
WHERE recommendation_score > 0
ORDER BY username, recommendation_score DESC;

-- ============================================================================
-- JSON VALIDATION AND QUALITY CHECKS
-- ============================================================================

-- 23. Data quality validation for JSON fields
SELECT 
    'user_profiles' AS table_name,
    COUNT(*) AS total_records,
    COUNT(CASE WHEN profile_data->>'first_name' IS NULL OR profile_data->>'first_name' = '' THEN 1 END) AS missing_first_name,
    COUNT(CASE WHEN profile_data->>'last_name' IS NULL OR profile_data->>'last_name' = '' THEN 1 END) AS missing_last_name,
    COUNT(CASE WHEN profile_data->>'age' IS NULL OR (profile_data->>'age')::INTEGER < 0 THEN 1 END) AS invalid_age,
    COUNT(CASE WHEN profile_data->'skills' IS NULL OR jsonb_array_length(profile_data->'skills') = 0 THEN 1 END) AS no_skills,
    AVG(LENGTH(profile_data::TEXT)) AS avg_json_size
FROM user_profiles;

-- 24. JSON structure consistency check
WITH json_keys AS (
    SELECT 
        username,
        json_object_keys(profile_data) AS profile_key
    FROM user_profiles
)
SELECT 
    profile_key,
    COUNT(*) AS key_frequency,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM user_profiles), 2) AS percentage_coverage
FROM json_keys
GROUP BY profile_key
ORDER BY key_frequency DESC;

-- ============================================================================
-- PERFORMANCE OPTIMIZATION HINTS
-- ============================================================================

-- 25. Efficient JSON queries with proper indexing hints
-- This query demonstrates how to structure queries for optimal performance

EXPLAIN (ANALYZE, BUFFERS) 
SELECT 
    username,
    profile_data->>'city' AS city,
    profile_data->'skills' AS skills
FROM user_profiles
WHERE profile_data->>'city' = 'New York'
  AND profile_data->'skills' ? 'Python';

-- 26. Batch JSON updates with optimal patterns
UPDATE user_profiles 
SET profile_data = profile_data || 
    json_build_object('last_updated', CURRENT_TIMESTAMP)::jsonb
WHERE (profile_data->>'age')::INTEGER > 25;

/*
 * LEARNING NOTES:
 * 
 * 1. JSON Query Performance:
 *    - Use JSONB for frequently queried data
 *    - Create GIN indexes on JSONB columns
 *    - Use -> for objects, ->> for text extraction
 *    - Avoid repeated JSON parsing in WHERE clauses
 * 
 * 2. JSON Path Expressions:
 *    - Use safe navigation with IS NOT NULL checks
 *    - Handle array bounds with jsonb_array_length()
 *    - Use COALESCE for default values
 * 
 * 3. Best Practices:
 *    - Validate JSON structure before complex queries
 *    - Use CTEs for complex JSON transformations
 *    - Consider materializing frequently accessed JSON paths
 *    - Monitor query performance with EXPLAIN ANALYZE
 * 
 * 4. Cross-Database Compatibility:
 *    - MySQL: Use JSON_EXTRACT(), JSON_UNQUOTE()
 *    - SQL Server: Use JSON_VALUE(), JSON_QUERY()
 *    - PostgreSQL: Use -> and ->> operators
 */

/*
 * File: 0-json_in_sql.sql
 * Description: Demonstrates JSON data storage and manipulation in SQL databases
 * Author: Alpha0-1
 * 
 * This file covers:
 * - Creating tables with JSON columns
 * - Inserting JSON data
 * - Basic JSON manipulation functions
 * - Data type validation
 */

-- ============================================================================
-- TABLE CREATION WITH JSON COLUMNS
-- ============================================================================

-- Create a table to store user profiles with JSON data
CREATE TABLE user_profiles (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL,
    profile_data JSON NOT NULL,
    preferences JSONB,  -- JSONB for better performance in PostgreSQL
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create a table for product catalog with complex JSON structure
CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    category VARCHAR(100),
    specifications JSON,
    pricing_data JSONB,
    metadata JSON,
    is_active BOOLEAN DEFAULT TRUE
);

-- Create a table for event logging with flexible JSON structure
CREATE TABLE event_logs (
    log_id SERIAL PRIMARY KEY,
    event_type VARCHAR(50) NOT NULL,
    event_data JSON NOT NULL,
    user_id INTEGER,
    timestamp_occurred TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    source_system VARCHAR(100)
);

-- ============================================================================
-- INSERTING JSON DATA
-- ============================================================================

-- Insert user profiles with JSON data
INSERT INTO user_profiles (username, email, profile_data, preferences) VALUES
('john_doe', 'john@example.com', 
 '{"first_name": "John", "last_name": "Doe", "age": 28, "city": "New York", "skills": ["Python", "SQL", "JavaScript"], "bio": "Software developer with 5 years experience"}',
 '{"theme": "dark", "notifications": {"email": true, "push": false}, "language": "en", "timezone": "EST"}'
),
('jane_smith', 'jane@example.com',
 '{"first_name": "Jane", "last_name": "Smith", "age": 32, "city": "San Francisco", "skills": ["Java", "React", "Node.js"], "bio": "Full-stack developer and team lead"}',
 '{"theme": "light", "notifications": {"email": true, "push": true}, "language": "en", "timezone": "PST"}'
),
('mike_wilson', 'mike@example.com',
 '{"first_name": "Mike", "last_name": "Wilson", "age": 25, "city": "Austin", "skills": ["Python", "Django", "PostgreSQL"], "bio": "Backend developer passionate about databases"}',
 '{"theme": "auto", "notifications": {"email": false, "push": true}, "language": "en", "timezone": "CST"}'
);

-- Insert product data with complex JSON structures
INSERT INTO products (name, category, specifications, pricing_data, metadata) VALUES
('Gaming Laptop Pro', 'Electronics',
 '{"processor": "Intel i7-12700H", "ram": "32GB DDR5", "storage": "1TB NVMe SSD", "graphics": "RTX 3070", "display": {"size": "15.6 inch", "resolution": "1920x1080", "refresh_rate": "144Hz"}, "ports": ["USB-C", "HDMI", "Ethernet"], "weight": "2.3kg"}',
 '{"base_price": 1299.99, "currency": "USD", "discounts": [{"type": "student", "percentage": 10}, {"type": "bulk", "min_quantity": 5, "percentage": 15}], "pricing_tiers": {"retail": 1299.99, "wholesale": 1099.99}}',
 '{"manufacturer": "TechCorp", "warranty_years": 2, "certifications": ["Energy Star", "EPEAT"], "tags": ["gaming", "high-performance", "portable"]}'
),
('Wireless Headphones', 'Audio',
 '{"type": "Over-ear", "connectivity": ["Bluetooth 5.0", "3.5mm jack"], "battery_life": "30 hours", "noise_cancellation": true, "frequency_response": "20Hz-20kHz", "weight": "250g", "colors": ["Black", "White", "Blue"]}',
 '{"base_price": 199.99, "currency": "USD", "discounts": [{"type": "seasonal", "percentage": 20}], "pricing_tiers": {"retail": 199.99, "wholesale": 159.99}}',
 '{"manufacturer": "AudioTech", "warranty_years": 1, "certifications": ["FCC"], "tags": ["wireless", "noise-cancelling", "premium"]}'
);

-- Insert event log data
INSERT INTO event_logs (event_type, event_data, user_id, source_system) VALUES
('user_login', '{"ip_address": "192.168.1.100", "user_agent": "Mozilla/5.0...", "session_id": "sess_12345", "login_method": "password"}', 1, 'web_app'),
('purchase_completed', '{"order_id": "ORD-2025-001", "total_amount": 1299.99, "payment_method": "credit_card", "items": [{"product_id": 1, "quantity": 1, "price": 1299.99}], "shipping_address": {"country": "USA", "state": "NY", "city": "New York"}}', 1, 'e_commerce'),
('profile_updated', '{"fields_changed": ["email", "preferences"], "old_email": "john.old@example.com", "new_email": "john@example.com"}', 1, 'profile_service');

-- ============================================================================
-- BASIC JSON MANIPULATION AND QUERIES
-- ============================================================================

-- Extract specific JSON fields (PostgreSQL syntax)
SELECT 
    username,
    profile_data->>'first_name' AS first_name,
    profile_data->>'last_name' AS last_name,
    profile_data->'age' AS age,
    profile_data->'skills' AS skills_array
FROM user_profiles;

-- Query users by age range using JSON data
SELECT 
    username,
    profile_data->>'first_name' AS first_name,
    (profile_data->>'age')::INTEGER AS age
FROM user_profiles
WHERE (profile_data->>'age')::INTEGER BETWEEN 25 AND 30;

-- Query users with specific skills
SELECT 
    username,
    profile_data->>'first_name' AS first_name,
    profile_data->'skills' AS skills
FROM user_profiles
WHERE profile_data->'skills' ? 'Python';  -- PostgreSQL JSONB operator

-- Extract nested JSON data from products
SELECT 
    name,
    specifications->>'processor' AS processor,
    specifications->'display'->>'size' AS display_size,
    pricing_data->>'base_price' AS base_price
FROM products;

-- ============================================================================
-- JSON VALIDATION AND CONSTRAINTS
-- ============================================================================

-- Function to validate JSON structure for user profiles
CREATE OR REPLACE FUNCTION validate_user_profile(profile_json JSON)
RETURNS BOOLEAN AS $$
BEGIN
    -- Check if required fields exist
    IF NOT (profile_json ? 'first_name' AND 
            profile_json ? 'last_name' AND 
            profile_json ? 'age') THEN
        RETURN FALSE;
    END IF;
    
    -- Validate age is a number and within reasonable range
    IF NOT ((profile_json->>'age')::INTEGER BETWEEN 13 AND 120) THEN
        RETURN FALSE;
    END IF;
    
    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END;
$$ LANGUAGE plpgsql;

-- Add constraint to validate user profile JSON
ALTER TABLE user_profiles 
ADD CONSTRAINT valid_profile_data 
CHECK (validate_user_profile(profile_data));

-- ============================================================================
-- UPDATING JSON DATA
-- ============================================================================

-- Update specific JSON fields
UPDATE user_profiles 
SET profile_data = jsonb_set(
    profile_data::jsonb, 
    '{age}', 
    '29'::jsonb
)
WHERE username = 'john_doe';

-- Add new field to JSON data
UPDATE user_profiles 
SET preferences = jsonb_set(
    preferences, 
    '{newsletter_subscription}', 
    'true'::jsonb
)
WHERE username = 'jane_smith';

-- Update nested JSON data
UPDATE products 
SET pricing_data = jsonb_set(
    pricing_data,
    '{discounts}',
    (pricing_data->'discounts')::jsonb || '[{"type": "loyalty", "percentage": 5}]'::jsonb
)
WHERE name = 'Gaming Laptop Pro';

-- ============================================================================
-- AGGREGATIONS WITH JSON DATA
-- ============================================================================

-- Count users by city
SELECT 
    profile_data->>'city' AS city,
    COUNT(*) AS user_count
FROM user_profiles
GROUP BY profile_data->>'city'
ORDER BY user_count DESC;

-- Average age by city
SELECT 
    profile_data->>'city' AS city,
    AVG((profile_data->>'age')::INTEGER) AS avg_age
FROM user_profiles
GROUP BY profile_data->>'city';

-- Count products by manufacturer
SELECT 
    metadata->>'manufacturer' AS manufacturer,
    COUNT(*) AS product_count,
    AVG((pricing_data->>'base_price')::DECIMAL) AS avg_price
FROM products
GROUP BY metadata->>'manufacturer';

-- ============================================================================
-- JSON ARRAY OPERATIONS
-- ============================================================================

-- Expand JSON arrays into rows
SELECT 
    username,
    profile_data->>'first_name' AS first_name,
    jsonb_array_elements_text(profile_data->'skills') AS skill
FROM user_profiles
WHERE profile_data->'skills' IS NOT NULL;

-- Count total skills across all users
WITH skill_expansion AS (
    SELECT jsonb_array_elements_text(profile_data->'skills') AS skill
    FROM user_profiles
    WHERE profile_data->'skills' IS NOT NULL
)
SELECT 
    skill,
    COUNT(*) AS skill_count
FROM skill_expansion
GROUP BY skill
ORDER BY skill_count DESC;

-- ============================================================================
-- CLEANUP AND EXAMPLES
-- ============================================================================

-- Example: Clean up invalid JSON data
-- This would remove any rows where JSON validation fails
/*
DELETE FROM user_profiles 
WHERE NOT validate_user_profile(profile_data);
*/

-- Example: Convert JSON to relational structure
CREATE VIEW user_profile_normalized AS
SELECT 
    id,
    username,
    email,
    profile_data->>'first_name' AS first_name,
    profile_data->>'last_name' AS last_name,
    (profile_data->>'age')::INTEGER AS age,
    profile_data->>'city' AS city,
    profile_data->>'bio' AS bio,
    preferences->>'theme' AS preferred_theme,
    preferences->'notifications'->>'email' AS email_notifications,
    created_at
FROM user_profiles;

-- Query the normalized view
SELECT * FROM user_profile_normalized 
WHERE age > 25 AND preferred_theme = 'dark';

/*
 * LEARNING NOTES:
 * 
 * 1. JSON vs JSONB in PostgreSQL:
 *    - JSON: Stores exact copy, slower queries
 *    - JSONB: Binary format, faster queries, supports indexing
 * 
 * 2. JSON Operators:
 *    - -> : Get JSON object field by key
 *    - ->> : Get JSON object field as text
 *    - ? : Does the string exist as a top-level key?
 *    - ?& : Do all of these array strings exist as top-level keys?
 *    - ?| : Do any of these array strings exist as top-level keys?
 * 
 * 3. Best Practices:
 *    - Use JSONB for frequently queried data
 *    - Validate JSON structure with constraints
 *    - Consider indexing for better performance
 *    - Don't overuse JSON - normalize when relationships are clear
 */

/*
  Filename: 2-postgresql_json.sql
  Description: Working with JSON data in PostgreSQL
  Author: Alpha0-1
*/

-- Step 1: Connect to the database
\c basic_db;

-- Step 2: Create a table with JSON columns
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50),
    preferences JSONB
);

-- Step 3: Insert JSON data
INSERT INTO users (name, preferences)
VALUES
('John Doe', '{"theme": "dark", "notifications": {"email": true, "sms": false}}'),
('Jane Smith', '{"theme": "light", "notifications": {"email": true, "sms": true}}');

-- Step 4: Query JSON data
-- Access specific JSON fields
SELECT name,
       preferences->>'theme' AS theme,
       (preferences->'notifications')->>'email' AS email_notifications
FROM users;

-- Step 5: Update JSON data
UPDATE users
SET preferences = jsonb_set(
    preferences,
    '{"notifications", "sms"}',
    'true'
)
WHERE name = 'John Doe';

-- Step 6: JSON array example
INSERT INTO users (name, preferences)
VALUES
('Bob Johnson', '{"favorites": ["music", "movies", "reading"]}');

-- Access array elements
SELECT name, (preferences->'favorites')[@] AS favorite
FROM users, JSONB_ARRAY_ELEMENTS(users.preferences->'favorites');

/*
  Exercise:
  1. Create a table with JSON data type
  2. Implement JSON array operations
  3. Practice using jsonb_exists()
*/

-- Cleanup
-- DROP TABLE users;

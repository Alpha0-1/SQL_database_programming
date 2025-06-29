-- Working with JSON data in SQL (MySQL syntax)

-- Create table with JSON column
CREATE TABLE IF NOT EXISTS user_profiles (
    user_id INT PRIMARY KEY,
    profile JSON
);

-- Insert JSON data
INSERT INTO user_profiles (user_id, profile) VALUES
(1, '{"name": "Alice", "age": 30, "hobbies": ["reading", "traveling"]}');

-- Extract JSON values
SELECT user_id, JSON_EXTRACT(profile, '$.name') AS name
FROM user_profiles;

-- Update JSON value
UPDATE user_profiles
SET profile = JSON_SET(profile, '$.age', 31)
WHERE user_id = 1;

-- Output updated record
SELECT * FROM user_profiles;

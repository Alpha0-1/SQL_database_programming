-- 8-views.sql: Creating Views for Simplified Queries

-- A view is a virtual table based on the result-set of an SQL query

-- Create a simple view
CREATE OR REPLACE VIEW active_users AS
SELECT user_id, email
FROM users
WHERE email IS NOT NULL;

-- Query the view
SELECT * FROM active_users;

-- Updatable view
CREATE OR REPLACE VIEW user_profiles AS
SELECT u.user_id, u.email, p.bio
FROM users u
JOIN profiles p ON u.user_id = p.user_id;

-- Update via view
UPDATE user_profiles SET bio = 'New Bio' WHERE user_id = 1;

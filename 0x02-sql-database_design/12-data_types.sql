-- 12-data_types.sql: Choosing Appropriate Data Types

-- Proper data types improve storage efficiency and performance

-- Use UUID instead of CHAR(36) for unique identifiers
CREATE TABLE IF NOT EXISTS uuid_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT
);

-- Use numeric instead of float/double for financial data
CREATE TABLE IF NOT EXISTS accounts (
    account_id SERIAL PRIMARY KEY,
    balance NUMERIC(15, 2) NOT NULL
);

-- Use JSONB for structured JSON data
CREATE TABLE IF NOT EXISTS settings (
    user_id INT PRIMARY KEY,
    preferences JSONB
);

-- Insert JSON data
INSERT INTO settings (user_id, preferences)
VALUES (1, '{"theme": "dark", "notifications": true}');

-- Query JSONB
SELECT user_id FROM settings WHERE preferences @> '{"theme": "dark"}';

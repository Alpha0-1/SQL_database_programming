-- 3-force_name.sql
-- Creates table with NOT NULL constraint on name column

-- Create table with NOT NULL constraint
CREATE TABLE IF NOT EXISTS force_name (
    id INT,
    name VARCHAR(255) NOT NULL
);

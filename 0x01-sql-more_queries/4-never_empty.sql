-- 4-never_empty.sql
-- Table with default value constraint

-- Create table with default value for name
CREATE TABLE IF NOT EXISTS never_empty (
    id INT,
    name VARCHAR(255) DEFAULT 'default_name'
);

-- 5-unique_id.sql
-- Table with unique constraint on id column

-- Create table with UNIQUE constraint
CREATE TABLE IF NOT EXISTS unique_id (
    id INT UNIQUE,
    name VARCHAR(255)
);

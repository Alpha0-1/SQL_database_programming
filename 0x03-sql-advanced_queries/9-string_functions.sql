-- 9-string_functions.sql
-- Purpose: Demonstrate string manipulation functions
-- Author: Alpha0-1

-- Table of user emails
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255)
);

-- Insert sample data
INSERT INTO users (email) VALUES
('alice@example.com'),
('bob.smith@workplace.org'),
('charlie.doe@school.edu');

-- Extract username from email
SELECT
    email,
    SUBSTRING(email FROM 1 FOR POSITION('@' IN email) - 1) AS username,
    UPPER(SUBSTRING(email FROM POSITION('@' IN email) + 1)) AS domain_upper
FROM users;

-- Replace part of a string
SELECT
    email,
    REPLACE(email, 'example.com', 'newdomain.net') AS updated_email
FROM users;

-- Concatenate strings
SELECT
    'User: ' || email || ' has been verified.' AS message
FROM users;

-- 11-mathematical_functions.sql
-- Purpose: Demonstrate mathematical functions
-- Author: Alpha0-1

-- Table of measurements
CREATE TABLE IF NOT EXISTS metrics (
    id SERIAL PRIMARY KEY,
    value NUMERIC(10,2)
);

-- Insert sample data
INSERT INTO metrics (value) VALUES
(10.25), (20.75), (30.00), (40.50);

-- Basic math operations
SELECT
    value,
    ROUND(value, 0) AS rounded_value,
    CEIL(value) AS ceiling_value,
    FLOOR(value) AS floor_value,
    SQRT(value) AS square_root,
    POWER(value, 2) AS squared
FROM metrics;

-- Random number generation
SELECT RANDOM() AS random_value;

-- Absolute value
SELECT ABS(-100) AS absolute_value;

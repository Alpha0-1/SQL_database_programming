/*
  Filename: 1-postgresql_arrays.sql
  Description: Working with PostgreSQL array data types
  Author: Alpha0-1
*/

-- Step 1: Connect to the database
\c basic_db;

-- Step 2: Create a table with array columns
CREATE TABLE employees (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    skills TEXT[]           -- Array of text strings
);

-- Step 3: Insert data with array values
INSERT INTO employees (first_name, last_name, skills)
VALUES
('John', 'Doe', '{SQL,Python,Java}'),     -- skills as an array
('Jane', 'Smith', '{PostgreSQL,React}');

-- Step 4: Accessing array elements
SELECT first_name, last_name, skills[1] AS first_skill
FROM employees;

-- Step 5: Array manipulation functions
-- Add an element to the array
UPDATE employees
SET skills = skills || '{JavaScript}'
WHERE first_name = 'John';

-- Step 6: Query arrays using containment operator
SELECT * FROM employees
WHERE skills @> '{SQL}';

/*
  Exercise:
  1. Create a table with an integer array column
  2. Practice using array functions like array_length
  3. Implement array joins usingunnest()
*/

-- Cleanup
-- DROP TABLE employees;

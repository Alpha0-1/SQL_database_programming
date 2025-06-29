/*
  Filename: 0-postgresql_basics.sql
  Description: Introduction to PostgreSQL with basic operations
  Author: Alpha0-1
*/

-- Step 1: Create a new database
CREATE DATABASE basic_db;

-- Step 2: Connect to the database
\c basic_db;

-- Step 3: Create a table with SERIAL for auto-incrementing ID
CREATE TABLE employees (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    salary NUMERIC(10, 2) DEFAULT 0,
    hire_date DATE,
    department VARCHAR(50)
);

-- Step 4: Insert data
INSERT INTO employees (first_name, last_name, salary, hire_date, department)
VALUES
('John', 'Doe', 50000.00, '2023-01-15', 'HR'),
('Jane', 'Smith', 65000.00, '2023-03-20', 'Engineering'),
('Bob', 'Johnson', 55000.00, '2023-05-10', 'Marketing');

-- Step 5: Basic SELECT query
SELECT * FROM employees;

-- Step 6: Filter and sort
SELECT first_name, last_name, salary 
FROM employees 
WHERE department = 'Engineering'
ORDER BY hire_date DESC;

/*
  Exercise:
  1. Add a new column 'email' with data type VARCHAR(100)
  2. Write a query to get employees with salary > 50000
  3. Try using LIMIT to get 2 employees
*/

-- Cleanup
-- DROP TABLE employees;
-- DROP DATABASE basic_db;

/*
  Filename: 0-sqlite_basics.sql
  Description: SQLite basics including database creation and basic queries
  Author: Alpha0-1
*/

-- Step 1: Create a new database (file)
-- Run with: sqlite3 basic_db.db < 0-sqlite_basics.sql

-- Step 2: Create a table
CREATE TABLE employees (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    salary REAL DEFAULT 0,
    hire_date DATE,
    department TEXT
);

-- Step 3: Insert data
INSERT INTO employees (first_name, last_name, salary, hire_date, department)
VALUES
('John', 'Doe', 50000.00, '2023-01-15', 'HR'),
('Jane', 'Smith', 65000.00, '2023-03-20', 'Engineering'),
('Bob', 'Johnson', 55000.00, '2023-05-10', 'Marketing');

-- Step 4: Basic SELECT query
SELECT * FROM employees;

-- Step 5: Filter and order
SELECT first_name, last_name, salary 
FROM employees 
WHERE department = 'Engineering'
ORDER BY hire_date DESC;

/*
  Exercise:
  1. Add a 'phone_number' column with text data type
  2. Write a query to get employees hired in the last 6 months
  3. Practice using LIMIT to get first 2 employees
*/

-- Cleanup
-- DROP TABLE employees;
-- Exit with: .exit

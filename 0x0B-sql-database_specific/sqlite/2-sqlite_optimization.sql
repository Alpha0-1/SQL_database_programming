/*
  Filename: 2-sqlite_optimization.sql
  Description: SQLite optimization techniques for faster queries and better performance
  Author: Alpha0-1
*/

-- Step 1: Create a performance test database
-- Run with: sqlite3 optimization.db < 2-sqlite_optimization.sql

-- Step 2: Create a table without indexes
CREATE TABLE employees (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    first_name TEXT,
    last_name TEXT,
    salary REAL,
    hire_date DATE
);

-- Step 3: Insert sample data
INSERT INTO employees (first_name, last_name, salary, hire_date) 
VALUES
('John', 'Doe', 50000.00, '2023-01-15'),
('Jane', 'Smith', 65000.00, '2023-03-20'),
('Bob', 'Johnson', 55000.00, '2023-05-10');

-- Step 4: Test query performance without indexes
EXPLAIN QUERY PLAN
SELECT * FROM employees WHERE first_name = 'John';

-- Step 5: Create an index to optimize the query
CREATE INDEX idx_first_name ON employees(first_name);

-- Step 6: Test the same query with the index
EXPLAIN QUERY PLAN
SELECT * FROM employees WHERE first_name = 'John';

-- Step 7: Analyze index usage
SELECT sql FROM sqlite_master WHERE type = 'index' AND name = 'idx_first_name';

-- Step 8: Optimize for large datasets
-- Enable the auto-vacuum feature (recommended for SQLite)
PRAGMA auto_vacuum = 1;

-- Step 9: Verification of auto-vacuum
PRAGMA auto_vacuum;

/*
  Exercise:
  1. Create a composite index on `last_name` and `hire_date`
  2. Write a query to test the performance improvement with the new index
  3. Experiment with the `PRAGMA` settings for performance tuning
*/

-- Cleanup
-- DROP TABLE employees;
-- Exit with: .exit

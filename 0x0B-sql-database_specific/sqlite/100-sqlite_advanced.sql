/*
  Filename: 100-sqlite_advanced.sql
  Description: Advanced features and techniques in SQLite
  Author: Alpha0-1
*/

-- Step 1: Create a database
-- Run with: sqlite3 advanced.db < 100-sqlite_advanced.sql

-- Step 2: Enable the virtual table for full-text search
CREATE VIRTUAL TABLE employees USING fts5(
    id INTEGER PRIMARY KEY,
    name,
    content
);

-- Step 3: Insert data with FTS
INSERT INTO employees VALUES
(1, 'John Doe', 'Software Engineer'),
(2, 'Jane Smith', 'Data Scientist'),
(3, 'Bob Johnson', 'Product Manager');

-- Step 4: Query using FTS
SELECT name, content
FROM employees
WHERE employees MATCH 'engineer';

-- Step 5: Create a virtual table for JSON
CREATE VIRTUAL TABLE json_data USING json1;
INSERT INTO json_data (json)
VALUES (
    '{"name": "John Doe", "age": 30, "skills": ["SQL", "Python"]}'
);

-- Step 6: Query JSON data
SELECT json_extract(json, '$.name') AS name,
       json_array_length(json, '$.skills') AS skill_count
FROM json_data;

-- Step 7: SQLite window functions
CREATE TABLE sales (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    product TEXT,
    amount REAL,
    date DATE
);

INSERT INTO sales (product, amount, date)
VALUES
('Product A', 100.00, '2023-01-01'),
('Product B', 200.00, '2023-01-01'),
('Product A', 150.00, '2023-01-02');

SELECT 
    product,
    date,
    amount,
    SUM(amount) OVER (PARTITION BY product) AS total_per_product
FROM sales;

-- Step 8: SQLite triggers
CREATE TABLE employee_audits (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    employee_id INTEGER,
    changed_date DATETIME,
    action TEXT
);

CREATE TRIGGER employee_audit_trigger
AFTER UPDATE ON employees
BEGIN
    INSERT INTO employee_audits (employee_id, changed_date, action)
    VALUES (new.id, CURRENT_TIMESTAMP, 'Updated');
END;

/*
  Exercise:
  1. Implement full-text search on a different dataset
  2. Practice using JSON functions for advanced data extraction
  3. Create a trigger for delete operations
*/

-- Cleanup
-- DROP TABLE employees, sales, employee_audits;
-- Exit with: .exit

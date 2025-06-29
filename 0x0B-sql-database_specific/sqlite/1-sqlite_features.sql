/*
  Filename: 1-sqlite_features.sql
  Description: Exploring SQLite features including triggers and custom functions
  Author: Alpha0-1
*/

-- Step 1: Create a database
-- Run with: sqlite3 features_db.db < 1-sqlite_features.sql

-- Step 2: Create tables
CREATE TABLE employees (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT,
    salary REAL,
    hire_date DATE
);

CREATE TABLE employee_audits (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    employee_id INTEGER,
    changed_date DATETIME,
    action TEXT
);

-- Step 3: Create a trigger
CREATE TRIGGER employee_audit_trigger
AFTER UPDATE ON employees
BEGIN
    INSERT INTO employee_audits (employee_id, changed_date, action)
    VALUES (old.id, CURRENT_TIMESTAMP, 'Updated');
END;

-- Step 4: Insert sample data
INSERT INTO employees (name, salary, hire_date) 
VALUES
('John Doe', 50000.00, '2023-01-15');

-- Step 5: Test the trigger by updating a record
UPDATE employees
SET salary = 55000.00
WHERE name = 'John Doe';

-- Step 6: View audit records
SELECT * FROM employee_audits;

/*
  Exercise:
  1. Create a trigger for delete operations
  2. Explore SQLite's CASE WHEN THEN ELSE END construct
  3. Practice using UNNEST() virtual table on arrays (SQLite 3.8.0+)
*/

-- Cleanup
-- DROP TABLE employees, employee_audits;
-- Exit with: .exit

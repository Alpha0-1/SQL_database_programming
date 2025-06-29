-- MySQL Optimization Techniques

-- Indexes improve query performance
CREATE INDEX idx_lastname ON employees(last_name);

-- Analyze query execution plan
EXPLAIN SELECT * FROM employees WHERE last_name = 'Doe';

-- Avoid SELECT *, specify needed columns
SELECT id, first_name, last_name FROM employees WHERE hire_date > '2023-01-01';

-- Use LIMIT to restrict results
SELECT * FROM employees ORDER BY hire_date DESC LIMIT 5;

-- Optimize JOINs with indexed columns
CREATE TABLE departments (
    dept_id INT PRIMARY KEY,
    dept_name VARCHAR(50)
);

ALTER TABLE employees ADD COLUMN dept_id INT;

CREATE INDEX idx_dept ON employees(dept_id);

SELECT e.first_name, e.last_name, d.dept_name
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id;

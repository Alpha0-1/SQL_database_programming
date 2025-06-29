/*
  Filename: 4-postgresql_cte.sql
  Description: PostgreSQL Common Table Expressions (CTEs) for advanced queries
  Author: Alpha0-1
*/

-- Step 1: Connect to the database
\c basic_db;

-- Step 2: Create a sample table
CREATE TABLE employees (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50),
    manager_id INT,
    department VARCHAR(50),
    salary DECIMAL(10, 2)
);

-- Step 3: Insert sample data
INSERT INTO employees (name, manager_id, department, salary)
VALUES
('John Doe', NULL, 'HR', 50000.00),
('Jane Smith', 1, 'HR', 55000.00),
('Bob Johnson', 1, 'Engineering', 60000.00);

-- Step 4: Simple CTE example
WITH manager_cte AS (
    SELECT id, name
    FROM employees
    WHERE department = 'HR'
)
SELECT * FROM manager_cte;

-- Step 5: Recursive CTE for hierarchical data
WITH RECURSIVE employee_hierarchy AS (
    SELECT id, name, manager_id
    FROM employees
    WHERE id = 1
    UNION ALL
    SELECT e.id, e.name, e.manager_id
    FROM employees e
    INNER JOIN employee_hierarchy eh ON e.manager_id = eh.id
)
SELECT * FROM employee_hierarchy;

-- Step 6: CTE for data aggregation
WITH salary_summary AS (
    SELECT department, SUM(salary) AS total_salary
    FROM employees
    GROUP BY department
)
SELECT department, total_salary, (
    SELECT SUM(salary) FROM employees
) AS company_total
FROM salary_summary;

/*
  Exercise:
  1. Create a CTE to calculate average salary per department
  2. Implement a recursive CTE to traverse a tree structure
  3. Use CTEs in complex JOIN operations
*/

-- Cleanup
-- DROP TABLE employees;

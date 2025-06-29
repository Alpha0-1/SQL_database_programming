/*
  Filename: 3-oracle_optimization.sql
  Description: Oracle database optimization techniques
  Author: Alpha0-1
*/

-- Step 1: Create a table
CREATE TABLE employees (
    employee_id NUMBER PRIMARY KEY,
    first_name VARCHAR2(50),
    last_name VARCHAR2(50),
    salary NUMBER(10, 2)
);

-- Step 2: Insert sample data
INSERT INTO employees VALUES
(1, 'John', 'Doe', 50000),
(2, 'Jane', 'Smith', 65000),
(3, 'Bob', 'Johnson', 55000);

-- Step 3: Create an index
CREATE INDEX idx_salary ON employees(salary);

-- Step 4: Optimize a query using indexing
SELECT employee_id, first_name, last_name, salary
FROM employees
WHERE salary > 50000;

-- Step 5: Use the EXPLAIN PLAN
EXPLAIN PLAN FOR
SELECT employee_id, first_name, last_name, salary
FROM employees
WHERE salary > 50000;

-- Step 6: Analytic functions for optimization
SELECT 
    employee_id,
    first_name,
    last_name,
    salary,
    RANK() OVER (ORDER BY salary DESC) salary_rank
FROM employees;

-- Step 7: Use materialized views for complex queries
CREATE MATERIALIZED VIEW mv_employee_summary
AS
SELECT 
    department_id,
    COUNT(*) AS employee_count,
    AVG(salary) AS average_salary
FROM employees
GROUP BY department_id;

/*
  Exercise:
  1. Implement a query with composite indexing
  2. Practice using analytic functions like LAG and LEAD
  3. Create a materialized view for a frequently used query
*/

-- Cleanup
-- DROP TABLE employees;
-- DROP INDEX idx_salary;
-- DROP MATERIALIZED VIEW mv_employee_summary;

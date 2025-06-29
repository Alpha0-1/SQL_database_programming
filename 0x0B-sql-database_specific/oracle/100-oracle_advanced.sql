/*
  Filename: 100-oracle_advanced.sql
  Description: Advanced Oracle database techniques
  Author: Alpha0-1
*/

-- Step 1: Create a materialized view
CREATE MATERIALIZED VIEW mv_employee_summary
BUILD IMMEDIATE
REFRESH COMPLETE ON DEMAND
AS
SELECT department, COUNT(*) AS employee_count, AVG(salary) AS avg_salary
FROM employees
GROUP BY department;

-- Step 2: Query the materialized view
SELECT * FROM mv_employee_summary;

-- Step 3: Refresh the materialized view
BEGIN
    DBMS_MVIEW.REFRESH('mv_employee_summary');
END;
/

-- Step 4: Create a database link to another Oracle instance
CREATE DATABASE LINK other_db_link
CONNECT TO remote_user IDENTIFIED BY remote_password
USING 'remote_server';

-- Step 5: Query data from the linked database
SELECT * FROM employees@other_db_link;

-- Step 6: Advanced analytic functions example
SELECT 
    employee_id,
    first_name,
    last_name,
    salary,
    RANK() OVER (ORDER BY salary DESC) AS salary_rank
FROM employees;

-- Step 7: Using the MODEL clause for complex calculations
SELECT *
FROM employees
MODEL
DISTINCT ON (department)
PARTITION BY (department)
DIMENSION BY (department)
MEASURES (AVG(salary) AS avg_salary)
RULES (
    avg_salary[department IS NOT NULL] =
        AVG(salary) OF employees[department]
);

/*
  Exercise:
  1. Create a materialized view with fast refresh
  2. Implement a stored procedure using a database link
  3. Practice using the MODEL clause with different scenarios
*/

-- Cleanup
-- DROP MATERIALIZED VIEW mv_employee_summary;
-- DROP DATABASE LINK other_db_link;
-- DROP TABLE employees;

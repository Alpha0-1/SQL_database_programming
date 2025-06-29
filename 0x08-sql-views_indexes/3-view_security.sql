/*
 * Title: Views for Security
 * Description: Demonstrates how views can be used to secure data and restrict access
 * 
 * Views can act as a security mechanism by:
 * - Hiding sensitive columns
 * - Restricting access to specific rows
 * - Controlling permissions through grants
 */

-- Step 1: Create a sample table with sensitive data
CREATE TABLE employees (
    employee_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    salary DECIMAL(10,2),
    department_id INT
);

-- Step 2: Populate sample data
INSERT INTO employees VALUES
    (1, 'John', 'Doe', 50000, 1),
    (2, 'Jane', 'Smith', 60000, 2),
    (3, 'Bob', 'Johnson', 55000, 1);

-- Step 3: Create a security-restricted view for non-management employees
CREATE VIEW employee_summary AS
SELECT 
    employee_id,
    first_name,
    last_name,
    department_id
FROM employees
WHERE department_id <> 1;  -- Exclude management department (dept_id=1)

-- Step 4: Grant access to the view
GRANT SELECT ON employee_summary TO public;

-- Step 5: Try to access sensitive salary information (should fail)
SELECT * FROM employee_summary;

-- Query to view salary (private table access is restricted)
/*
 * Only users with permissions on the base table can access salary
 * data directly. The view hides salary for non-management employees.
 */

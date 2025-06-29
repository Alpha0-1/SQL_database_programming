/*
 * Title: Basic View Creation
 * Description: Demonstrates how to create and use basic SQL views
 * 
 * A view is a virtual table based on the result of a query. This example shows:
 * - How to create a simple view
 * - How to use the view like a table
 * - How views provide abstraction and simplification
 */

-- Step 1: Create a sample table
CREATE TABLE employees (
    employee_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    department_id INT,
    salary DECIMAL(10,2)
);

-- Step 2: Populate sample data
INSERT INTO employees VALUES
    (1, 'John', 'Doe', 1, 50000),
    (2, 'Jane', 'Smith', 2, 60000),
    (3, 'Bob', 'Johnson', 1, 55000);

-- Step 3: Create a basic view showing employee details
CREATE VIEW employee_details AS
SELECT 
    employee_id,
    first_name,
    last_name,
    salary
FROM employees
WHERE department_id = 1;

-- Step 4: Query the view
SELECT * FROM employee_details;

/*
 * Explanation:
 * - Views allow you to simplify complex queries
 * - They can encapsulate logic and provide abstraction
 * - Queries against views are executed against the underlying tables
 */

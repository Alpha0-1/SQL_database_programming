-- =============================================================================
-- File: 1-bulk_update.sql
-- Description: Bulk data update techniques and best practices
-- Author: Alpha0-1
-- =============================================================================

-- Create sample table if it doesn't exist
CREATE TABLE IF NOT EXISTS employees (
    id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE,
    department VARCHAR(50),
    salary DECIMAL(10,2),
    hire_date DATE,
    performance_rating VARCHAR(20) DEFAULT 'Not Rated',
    last_review_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Insert sample data if table is empty
INSERT IGNORE INTO employees (first_name, last_name, email, department, salary, hire_date)
VALUES 
    ('John', 'Doe', 'john.doe@company.com', 'Engineering', 75000.00, '2023-01-15'),
    ('Jane', 'Smith', 'jane.smith@company.com', 'Marketing', 65000.00, '2023-01-20'),
    ('Mike', 'Johnson', 'mike.johnson@company.com', 'Sales', 70000.00, '2023-02-01'),
    ('Sarah', 'Wilson', 'sarah.wilson@company.com', 'HR', 60000.00, '2023-02-10'),
    ('David', 'Brown', 'david.brown@company.com', 'Finance', 80000.00, '2023-02-15'),
    ('Lisa', 'Garcia', 'lisa.garcia@company.com', 'Engineering', 77000.00, '2023-03-01'),
    ('Tom', 'Miller', 'tom.miller@company.com', 'Sales', 68000.00, '2023-03-05'),
    ('Amy', 'Davis', 'amy.davis@company.com', 'Marketing', 63000.00, '2023-03-10');

-- =============================================================================
-- METHOD 1: SIMPLE BULK UPDATE BY CONDITION
-- =============================================================================

-- Update all employees in a specific department
UPDATE employees 
SET salary = salary * 1.10,  -- 10% salary increase
    performance_rating = 'Good',
    last_review_date = CURDATE()
WHERE department = 'Engineering';

-- Verify the update
SELECT first_name, last_name, department, salary, performance_rating
FROM employees 
WHERE department = 'Engineering';

-- =============================================================================
-- METHOD 2: CONDITIONAL BULK UPDATE WITH CASE STATEMENTS
-- =============================================================================

-- Update salaries based on different criteria
UPDATE employees 
SET salary = CASE 
    WHEN department = 'Sales' AND salary < 70000 THEN salary * 1.15      -- 15% increase for Sales under 70k
    WHEN department = 'Marketing' THEN salary * 1.08                      -- 8% increase for Marketing
    WHEN department = 'HR' THEN salary * 1.12                            -- 12% increase for HR
    WHEN hire_date < '2023-02-01' THEN salary * 1.05                     -- 5% for early hires
    ELSE salary                                                           -- No change for others
END,
performance_rating = CASE
    WHEN salary > 75000 THEN 'Excellent'
    WHEN salary > 65000 THEN 'Good'
    ELSE 'Average'
END
WHERE department IN ('Sales', 'Marketing', 'HR') OR hire_date < '2023-02-01';

-- =============================================================================
-- METHOD 3: UPDATE FROM ANOTHER TABLE (JOIN UPDATE)
-- =============================================================================

-- Create a temporary table with updated information
CREATE TEMPORARY TABLE salary_adjustments (
    employee_email VARCHAR(100),
    new_salary DECIMAL(10,2),
    rating VARCHAR(20),
    review_date DATE
);

-- Insert adjustment data
INSERT INTO salary_adjustments VALUES
    ('john.doe@company.com', 85000.00, 'Excellent', '2024-06-15'),
    ('jane.smith@company.com', 72000.00, 'Very Good', '2024-06-16'),
    ('mike.johnson@company.com', 78000.00, 'Good', '2024-06-17');

-- Update employees table using data from adjustments table
UPDATE employees e
INNER JOIN salary_adjustments sa ON e.email = sa.employee_email
SET 
    e.salary = sa.new_salary,
    e.performance_rating = sa.rating,
    e.last_review_date = sa.review_date;

-- =============================================================================
-- METHOD 4: BULK UPDATE WITH SUBQUERIES
-- =============================================================================

-- Update based on calculated values from the same table
UPDATE employees 
SET salary = (
    SELECT AVG(salary) * 1.1 
    FROM (SELECT salary FROM employees WHERE department = employees.department) as dept_avg
)
WHERE performance_rating = 'Average' 
AND department IN ('Finance', 'HR');

-- Update employees who earn less than the department average
UPDATE employees e1
SET salary = salary * 1.08
WHERE salary < (
    SELECT AVG(salary) 
    FROM (SELECT salary FROM employees WHERE department = e1.department) as dept_salary
);

-- =============================================================================
-- METHOD 5: BATCH UPDATE WITH TRANSACTIONS
-- =============================================================================

-- Safe bulk update using transactions
START TRANSACTION;

-- Store original state for potential rollback
CREATE TEMPORARY TABLE backup_employees AS 
SELECT id, salary, performance_rating, last_review_date 
FROM employees;

-- Perform bulk update
UPDATE employees 
SET 
    salary = CASE 
        WHEN YEAR(hire_date) = 2023 THEN salary * 1.06  -- 6% for employees hired in 2023
        ELSE salary * 1.03                              -- 3% for others
    END,
    last_review_date = CURDATE()
WHERE last_review_date IS NULL OR last_review_date < DATE_SUB(CURDATE(), INTERVAL 6 MONTH);

-- Check the number of affected rows
SELECT ROW_COUNT() as rows_updated;

-- Verify the changes look correct
SELECT 
    COUNT(*) as total_employees,
    AVG(salary) as avg_salary,
    MIN(salary) as min_salary,
    MAX(salary) as max_salary
FROM employees;

-- Commit if everything looks good, otherwise ROLLBACK
COMMIT;
-- ROLLBACK;  -- Use this instead of COMMIT if you need to undo

-- =============================================================================
-- METHOD 6: UPDATE WITH RANKING/ROW_NUMBER
-- =============================================================================

-- Update performance ratings based on salary ranking within department
UPDATE employees e1
SET performance_rating = (
    CASE 
        WHEN (
            SELECT COUNT(*) 
            FROM employees e2 
            WHERE e2.department = e1.department 
            AND e2.salary > e1.salary
        ) = 0 THEN 'Top Performer'
        WHEN (
            SELECT COUNT(*) 
            FROM employees e2 
            WHERE e2.department = e1.department 
            AND e2.salary > e1.salary
        ) <= 1 THEN 'High Performer'
        ELSE 'Standard Performer'
    END
);

-- =============================================================================
-- METHOD 7: CONDITIONAL UPDATE WITH EXISTS
-- =============================================================================

-- Create a table for bonus eligibility
CREATE TEMPORARY TABLE bonus_eligible (
    department VARCHAR(50),
    min_tenure_months INT
);

INSERT INTO bonus_eligible VALUES
    ('Engineering', 12),
    ('Sales', 6),
    ('Marketing', 9);

-- Update employees eligible for bonus
UPDATE employees e
SET performance_rating = CONCAT(performance_rating, ' - Bonus Eligible')
WHERE EXISTS (
    SELECT 1 
    FROM bonus_eligible be 
    WHERE be.department = e.department 
    AND TIMESTAMPDIFF(MONTH, e.hire_date, CURDATE()) >= be.min_tenure_months
)
AND performance_rating NOT LIKE '%Bonus Eligible%';

-- =============================================================================
-- PERFORMANCE MONITORING AND VERIFICATION
-- =============================================================================

-- Monitor the updates we've made
SELECT 
    department,
    COUNT(*) as employee_count,
    ROUND(AVG(salary), 2) as avg_salary,
    MIN(salary) as min_salary,
    MAX(salary) as max_salary,
    GROUP_CONCAT(DISTINCT performance_rating) as ratings
FROM employees
GROUP BY department
ORDER BY avg_salary DESC;

-- Check for any anomalies
SELECT 
    id,
    first_name,
    last_name,
    department,
    salary,
    performance_rating,
    TIMESTAMPDIFF(MONTH, hire_date, CURDATE()) as tenure_months
FROM employees
WHERE salary > 100000 OR salary < 50000  -- Flag unusual salaries
ORDER BY salary DESC;

-- =============================================================================
-- ROLLBACK PREPARATION (Advanced)
-- =============================================================================

-- For critical updates, consider creating a rollback script
/*
-- Example rollback using backup table
UPDATE employees e
INNER JOIN backup_employees be ON e.id = be.id
SET 
    e.salary = be.salary,
    e.performance_rating = be.performance_rating,
    e.last_review_date = be.last_review_date;
*/

-- =============================================================================
-- CLEANUP
-- =============================================================================

-- Clean up temporary tables
DROP TEMPORARY TABLE IF EXISTS salary_adjustments;
DROP TEMPORARY TABLE IF EXISTS backup_employees;
DROP TEMPORARY TABLE IF EXISTS bonus_eligible;

-- =============================================================================
-- BEST PRACTICES SUMMARY
-- =============================================================================

/*
BULK UPDATE BEST PRACTICES:

1. ALWAYS USE TRANSACTIONS for critical updates
   - START TRANSACTION before bulk updates
   - Test with small datasets first
   - COMMIT only after verification

2. CREATE BACKUPS before major updates
   - Create temporary backup tables
   - Store original values for rollback

3. USE APPROPRIATE WHERE CLAUSES
   - Be specific to avoid unintended updates
   - Test WHERE conditions with SELECT first

4. OPTIMIZE FOR PERFORMANCE
   - Update in batches for very large datasets
   - Consider disabling indexes temporarily for massive updates
   - Use LIMIT for batch processing

5. VERIFY RESULTS
   - Check row counts before and after
   - Validate data integrity
   - Monitor for unexpected changes

6. HANDLE ERRORS GRACEFULLY
   - Use proper error handling
   - Plan for rollback scenarios
   - Log important changes

7. CONSIDER CONCURRENCY
   - Be aware of locking implications
   - Schedule major updates during low-traffic periods
   - Use appropriate isolation levels
*/

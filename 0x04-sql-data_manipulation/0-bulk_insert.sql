i-- =============================================================================
-- File: 0-bulk_insert.sql
-- Description: Bulk data insertion techniques and best practices
-- Author: Alpha0-1
-- =============================================================================

-- =============================================================================
-- BASIC BULK INSERT OPERATIONS
-- =============================================================================

-- Create sample table for demonstration
CREATE TABLE IF NOT EXISTS employees (
    id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE,
    department VARCHAR(50),
    salary DECIMAL(10,2),
    hire_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- METHOD 1: INSERT MULTIPLE VALUES (Most Common)
-- =============================================================================

-- Insert multiple records in a single statement
-- This is more efficient than individual INSERT statements
INSERT INTO employees (first_name, last_name, email, department, salary, hire_date)
VALUES 
    ('John', 'Doe', 'john.doe@company.com', 'Engineering', 75000.00, '2024-01-15'),
    ('Jane', 'Smith', 'jane.smith@company.com', 'Marketing', 65000.00, '2024-01-20'),
    ('Mike', 'Johnson', 'mike.johnson@company.com', 'Sales', 70000.00, '2024-02-01'),
    ('Sarah', 'Wilson', 'sarah.wilson@company.com', 'HR', 60000.00, '2024-02-10'),
    ('David', 'Brown', 'david.brown@company.com', 'Finance', 80000.00, '2024-02-15');

-- =============================================================================
-- METHOD 2: INSERT FROM SELECT (Data Migration)
-- =============================================================================

-- Create a temporary table with sample data
CREATE TEMPORARY TABLE temp_employees (
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    department VARCHAR(50),
    salary DECIMAL(10,2),
    hire_date DATE
);

-- Insert sample data into temporary table
INSERT INTO temp_employees VALUES
    ('Alice', 'Cooper', 'alice.cooper@company.com', 'Engineering', 78000.00, '2024-03-01'),
    ('Bob', 'Martinez', 'bob.martinez@company.com', 'Marketing', 67000.00, '2024-03-05'),
    ('Carol', 'Davis', 'carol.davis@company.com', 'Sales', 72000.00, '2024-03-10');

-- Insert from another table (useful for data migration)
INSERT INTO employees (first_name, last_name, email, department, salary, hire_date)
SELECT first_name, last_name, email, department, salary, hire_date
FROM temp_employees
WHERE salary > 65000;

-- =============================================================================
-- METHOD 3: INSERT WITH CALCULATIONS
-- =============================================================================

-- Insert data with calculated values
INSERT INTO employees (first_name, last_name, email, department, salary, hire_date)
SELECT 
    CONCAT('Employee', ROW_NUMBER() OVER()) as first_name,
    'Generated' as last_name,
    CONCAT('emp', ROW_NUMBER() OVER(), '@company.com') as email,
    'IT' as department,
    50000 + (RAND() * 30000) as salary,  -- Random salary between 50k-80k
    DATE_SUB(CURDATE(), INTERVAL FLOOR(RAND() * 365) DAY) as hire_date
FROM (
    SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5
) as numbers;

-- =============================================================================
-- METHOD 4: CONDITIONAL BULK INSERT
-- =============================================================================

-- Insert only if certain conditions are met
INSERT INTO employees (first_name, last_name, email, department, salary, hire_date)
SELECT 
    'Conditional',
    'Employee',
    'conditional@company.com',
    'Special Projects',
    90000.00,
    CURDATE()
WHERE NOT EXISTS (
    SELECT 1 FROM employees WHERE email = 'conditional@company.com'
);

-- =============================================================================
-- METHOD 5: BULK INSERT WITH ERROR HANDLING
-- =============================================================================

-- Using transactions for safe bulk operations
START TRANSACTION;

-- Insert with error handling capability
INSERT IGNORE INTO employees (first_name, last_name, email, department, salary, hire_date)
VALUES 
    ('Test', 'User1', 'test1@company.com', 'Testing', 55000.00, '2024-03-15'),
    ('Test', 'User2', 'test2@company.com', 'Testing', 55000.00, '2024-03-15'),
    ('Test', 'User3', 'john.doe@company.com', 'Testing', 55000.00, '2024-03-15'); -- This will be ignored due to duplicate email

-- Check if the insertion was successful
SELECT ROW_COUNT() as rows_affected;

-- Commit the transaction
COMMIT;

-- =============================================================================
-- PERFORMANCE OPTIMIZATION TECHNIQUES
-- =============================================================================

-- Disable autocommit for better performance during bulk operations
-- SET autocommit = 0;

-- For very large datasets, consider using LOAD DATA INFILE
-- LOAD DATA INFILE '/path/to/datafile.csv'
-- INTO TABLE employees
-- FIELDS TERMINATED BY ','
-- LINES TERMINATED BY '\n'
-- IGNORE 1 ROWS;

-- =============================================================================
-- MONITORING AND VERIFICATION
-- =============================================================================

-- Check the results of our bulk inserts
SELECT 
    department,
    COUNT(*) as employee_count,
    AVG(salary) as avg_salary,
    MIN(hire_date) as earliest_hire,
    MAX(hire_date) as latest_hire
FROM employees
GROUP BY department
ORDER BY employee_count DESC;

-- Verify data integrity
SELECT 
    COUNT(*) as total_employees,
    COUNT(DISTINCT email) as unique_emails,
    COUNT(*) - COUNT(DISTINCT email) as duplicate_emails
FROM employees;

-- =============================================================================
-- CLEANUP (Optional - for testing purposes)
-- =============================================================================
DELETE FROM employees WHERE department IN ('Testing', 'Special Projects', 'IT');
DELETE FROM employees WHERE first_name LIKE 'Employee%';

-- =============================================================================
-- BEST PRACTICES SUMMARY
-- =============================================================================

/*
1. Use INSERT with multiple VALUES for small to medium datasets
2. Use INSERT ... SELECT for data migration between tables
3. Always use transactions for critical bulk operations
4. Consider using INSERT IGNORE or ON DUPLICATE KEY UPDATE for handling duplicates
5. Monitor performance and consider LOAD DATA INFILE for very large datasets
6. Validate data before and after bulk operations
7. Create indexes after bulk inserts, not before (for better performance)
8. Use appropriate batch sizes (typically 1000-10000 rows per batch)
*/

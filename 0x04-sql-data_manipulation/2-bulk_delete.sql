-- =============================================================================
-- File: 2-bulk_delete.sql
-- Description: Bulk data deletion techniques and safety practices
-- Author: Alpha0-1
-- =============================================================================

-- =============================================================================
-- SETUP: Create test data for deletion examples
-- =============================================================================

-- Create main table with sample data
CREATE TABLE IF NOT EXISTS employees (
    id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE,
    department VARCHAR(50),
    salary DECIMAL(10,2),
    hire_date DATE,
    termination_date DATE,
    status VARCHAR(20) DEFAULT 'Active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create related tables for referential integrity examples
CREATE TABLE IF NOT EXISTS employee_projects (
    id INT AUTO_INCREMENT PRIMARY KEY,
    employee_id INT,
    project_name VARCHAR(100),
    start_date DATE,
    end_date DATE,
    FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE
);

-- Insert sample data
INSERT IGNORE INTO employees (first_name, last_name, email, department, salary, hire_date, status, termination_date)
VALUES 
    ('John', 'Doe', 'john.doe@company.com', 'Engineering', 75000.00, '2022-01-15', 'Active', NULL),
    ('Jane', 'Smith', 'jane.smith@company.com', 'Marketing', 65000.00, '2022-01-20', 'Terminated', '2024-05-01'),
    ('Mike', 'Johnson', 'mike.johnson@company.com', 'Sales', 70000.00, '2022-02-01', 'Terminated', '2024-04-15'),
    ('Sarah', 'Wilson', 'sarah.wilson@company.com', 'HR', 60000.00, '2022-02-10', 'Active', NULL),
    ('David', 'Brown', 'david.brown@company.com', 'Finance', 80000.00, '2022-02-15', 'Terminated', '2024-03-30'),
    ('Lisa', 'Garcia', 'lisa.garcia@company.com', 'Engineering', 77000.00, '2023-03-01', 'Active', NULL),
    ('Tom', 'Miller', 'tom.miller@company.com', 'Sales', 68000.00, '2021-03-05', 'Inactive', NULL),
    ('Amy', 'Davis', 'amy.davis@company.com', 'Marketing', 63000.00, '2020-03-10', 'Inactive', NULL),
    ('Bob', 'Wilson', 'bob.wilson@company.com', 'IT', 72000.00, '2019-01-01', 'Terminated', '2024-01-01'),
    ('Carol', 'Taylor', 'carol.taylor@company.com', 'Finance', 69000.00, '2018-06-15', 'Terminated', '2023-12-31');

-- Insert related project data
INSERT IGNORE INTO employee_projects (employee_id, project_name, start_date, end_date)
VALUES 
    (1, 'Database Migration', '2024-01-01', '2024-06-30'),
    (2, 'Marketing Campaign Q1', '2024-01-01', '2024-03-31'),
    (3, 'Sales Analytics', '2024-02-01', '2024-05-31'),
    (4, 'HR System Upgrade', '2024-03-01', NULL),
    (5, 'Financial Reporting', '2024-01-01', '2024-04-30');

-- =============================================================================
-- SAFETY FIRST: PRE-DELETION CHECKS AND BACKUPS
-- =============================================================================

-- Always count records before deletion
SELECT 
    'Total Records' as description,
    COUNT(*) as count 
FROM employees
UNION ALL
SELECT 
    'Terminated Records',
    COUNT(*) 
FROM employees 
WHERE status = 'Terminated'
UNION ALL
SELECT 
    'Records to Delete (example)',
    COUNT(*) 
FROM employees 
WHERE status = 'Terminated' AND termination_date < '2024-01-01';

-- Create backup before deletion (CRITICAL SAFETY PRACTICE)
CREATE TABLE employees_backup AS 
SELECT * FROM employees;

-- =============================================================================
-- METHOD 1: SIMPLE CONDITIONAL BULK DELETE
-- =============================================================================

-- Delete terminated employees from previous year
START TRANSACTION;

-- First, let's see what we're about to delete
SELECT id, first_name, last_name, department, status, termination_date
FROM employees 
WHERE status = 'Terminated' 
AND termination_date < '2024-01-01';

-- Perform the deletion
DELETE FROM employees 
WHERE status = 'Terminated' 
AND termination_date < '2024-01-01';

-- Check how many rows were affected
SELECT ROW_COUNT() as rows_deleted;

COMMIT;

-- =============================================================================
-- METHOD 2: DELETE WITH JOIN (Complex Conditions)
-- =============================================================================

-- Delete employees who have no active projects
START TRANSACTION;

-- First, identify records to be deleted
SELECT DISTINCT e.id, e.first_name, e.last_name, e.department
FROM employees e
LEFT JOIN employee_projects ep ON e.id = ep.employee_id 
    AND (ep.end_date IS NULL OR ep.end_date > CURDATE())
WHERE ep.employee_id IS NULL 
AND e.status = 'Inactive';

-- Perform deletion using subquery (safer approach)
DELETE FROM employees 
WHERE id IN (
    SELECT emp_id FROM (
        SELECT DISTINCT e.id as emp_id
        FROM employees e
        LEFT JOIN employee_projects ep ON e.id = ep.employee_id 
            AND (ep.end_date IS NULL OR ep.end_date > CURDATE())
        WHERE ep.employee_id IS NULL 
        AND e.status = 'Inactive'
    ) as to_delete
);

COMMIT;

-- =============================================================================
-- METHOD 3: BATCH DELETE (For Large Datasets)
-- =============================================================================

-- For very large datasets, delete in batches to avoid locking issues
DELIMITER //

CREATE PROCEDURE batch_delete_old_records()
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE batch_size INT DEFAULT 1000;
    DECLARE deleted_count INT DEFAULT 0;
    DECLARE total_deleted INT DEFAULT 0;
    
    -- Enable error handling
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION 
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    REPEAT
        START TRANSACTION;
        
        -- Delete a batch of old records
        DELETE FROM employees 
        WHERE hire_date < '2019-01-01' 
        AND status = 'Terminated'
        LIMIT batch_size;
        
        SET deleted_count = ROW_COUNT();
        SET total_deleted = total_deleted + deleted_count;
        
        COMMIT;
        
        -- Small delay to reduce system load
        SELECT SLEEP(0.1);
        
    UNTIL deleted_count = 0 END REPEAT;
    
    SELECT CONCAT('Total records deleted: ', total_deleted) as result;
END //

DELIMITER ;

-- Execute the batch delete procedure
-- CALL batch_delete_old_records();

-- =============================================================================
-- METHOD 4: DELETE WITH EXISTS (Subquery Approach)
-- =============================================================================

-- Delete employees who exist in a specific list or condition
CREATE TEMPORARY TABLE employees_to_remove (
    email VARCHAR(100)
);

-- Add emails of employees to be removed
INSERT INTO employees_to_remove VALUES
    ('bob.wilson@company.com'),
    ('carol.taylor@company.com');

-- Delete using EXISTS
DELETE FROM employees 
WHERE EXISTS (
    SELECT 1 FROM employees_to_remove etr 
    WHERE etr.email = employees.email
);

-- =============================================================================
-- METHOD 5: CASCADING DELETE (Foreign Key Relationships)
-- =============================================================================

-- The employee_projects table has ON DELETE CASCADE
-- So deleting an employee will automatically delete their projects

-- First, let's see the relationships
SELECT 
    e.id,
    e.first_name,
    e.last_name,
    COUNT(ep.id) as project_count
FROM employees e
LEFT JOIN employee_projects ep ON e.id = ep.employee_id
GROUP BY e.id, e.first_name, e.last_name;

-- Delete employee (this will cascade to employee_projects)
DELETE FROM employees 
WHERE status = 'Terminated' 
AND termination_date IS NOT NULL 
AND id = 2;  -- Specific employee

-- =============================================================================
-- METHOD 6: CONDITIONAL DELETE WITH CASE LOGIC
-- =============================================================================

-- Delete based on complex business rules
DELETE FROM employees 
WHERE 
    CASE 
        WHEN department = 'Sales' AND status = 'Inactive' THEN TRUE
        WHEN department = 'Marketing' AND hire_date < '2021-01-01' AND status != 'Active' THEN TRUE
        WHEN status = 'Terminated' AND TIMESTAMPDIFF(YEAR, termination_date, CURDATE()) >= 2 THEN TRUE
        ELSE FALSE
    END = TRUE;

-- =============================================================================
-- METHOD 7: SOFT DELETE (Recommended for Important Data)
-- =============================================================================

-- Instead of hard delete, mark records as deleted
-- Add deleted_at column if it doesn't exist
ALTER TABLE employees 
ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP NULL,
ADD COLUMN IF NOT EXISTS deleted_by VARCHAR(50) NULL;

-- Soft delete implementation
UPDATE employees 
SET 
    deleted_at = NOW(),
    deleted_by = USER(),
    status = 'Deleted'
WHERE status = 'Terminated' 
AND termination_date < DATE_SUB(CURDATE(), INTERVAL 1 YEAR);

-- Create view for active employees (excluding soft-deleted)
CREATE OR REPLACE VIEW active_employees AS
SELECT * FROM employees 
WHERE deleted_at IS NULL;

-- =============================================================================
-- DATA ARCHIVING BEFORE DELETE
-- =============================================================================

-- Create archive table for historical data
CREATE TABLE IF NOT EXISTS employees_archive LIKE employees


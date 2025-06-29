-- =============================================================================
-- File: 4-merge_statements.sql
-- Description: MERGE operations for complex data synchronization
-- Author: Alpha
-- Note: MERGE syntax varies by database - examples for SQL Server/PostgreSQL
-- =============================================================================

-- =============================================================================
-- SETUP: Create tables for MERGE examples
-- =============================================================================

-- Source table (new data coming in)
CREATE TABLE IF NOT EXISTS employee_updates (
    employee_id VARCHAR(10) PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    department VARCHAR(50),
    salary DECIMAL(10,2),
    status VARCHAR(20),
    last_modified TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Target table (existing data)
CREATE TABLE IF NOT EXISTS employees_master (
    employee_id VARCHAR(10) PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    department VARCHAR(50),
    salary DECIMAL(10,2),
    status VARCHAR(20) DEFAULT 'Active',
    hire_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Audit table to track changes
CREATE TABLE IF NOT EXISTS merge_audit_log (
    id INT AUTO_INCREMENT PRIMARY KEY,
    employee_id VARCHAR(10),
    action_type ENUM('INSERT', 'UPDATE', 'DELETE'),
    old_values JSON,
    new_values JSON,
    merge_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- POPULATE INITIAL DATA
-- =============================================================================

-- Insert existing employees
INSERT IGNORE INTO employees_master (employee_id, first_name, last_name, email, department, salary, hire_date)
VALUES 
    ('EMP001', 'John', 'Doe', 'john.doe@company.com', 'Engineering', 75000.00, '2023-01-15'),
    ('EMP002', 'Jane', 'Smith', 'jane.smith@company.com', 'Marketing', 65000.00, '2023-01-20'),
    ('EMP003', 'Mike', 'Johnson', 'mike.johnson@company.com', 'Sales', 70000.00, '2023-02-01'),
    ('EMP004', 'Sarah', 'Wilson', 'sarah.wilson@company.com', 'HR', 60000.00, '2023-02-10');

-- Insert update data (mix of new, updated, and unchanged records)
INSERT INTO employee_updates (employee_id, first_name, last_name, email, department, salary, status)
VALUES 
    ('EMP001', 'John', 'Doe', 'john.doe@company.com', 'Senior Engineering', 85000.00, 'Active'),  -- Promotion
    ('EMP002', 'Jane', 'Smith-Brown', 'jane.smith@company.com', 'Marketing', 65000.00, 'Active'),  -- Name change
    ('EMP003', 'Mike', 'Johnson', 'mike.johnson@company.com', 'Sales', 70000.00, 'Terminated'),    -- Status change
    ('EMP005', 'David', 'Brown', 'david.brown@company.com', 'Finance', 72000.00, 'Active'),        -- New employee
    ('EMP006', 'Lisa', 'Garcia', 'lisa.garcia@company.com', 'IT', 78000.00, 'Active');             -- New employee

-- =============================================================================
-- METHOD 1: MYSQL MERGE SIMULATION (Using Multiple Statements)
-- MySQL doesn't have native MERGE, so we simulate it
-- =============================================================================

-- Start transaction for atomic merge operation
START TRANSACTION;

-- Step 1: Update existing records
UPDATE employees_master em
INNER JOIN employee_updates eu ON em.employee_id = eu.employee_id
SET 
    em.first_name = eu.first_name,
    em.last_name = eu.last_name,
    em.email = eu.email,
    em.department = eu.department,
    em.salary = eu.salary,
    em.status = eu.status,
    em.updated_at = CURRENT_TIMESTAMP;

-- Log updates to audit table
INSERT INTO merge_audit_log (employee_id, action_type, old_values, new_values)
SELECT 
    eu.employee_id,
    'UPDATE',
    JSON_OBJECT(
        'first_name', em.first_name,
        'last_name', em.last_name,
        'department', em.department,
        'salary', em.salary,
        'status', em.status
    ),
    JSON_OBJECT(
        'first_name', eu.first_name,
        'last_name', eu.last_name,
        'department', eu.department,
        'salary', eu.salary,
        'status', eu.status
    )
FROM employee_updates eu
INNER JOIN employees_master em ON em.employee_id = eu.employee_id
WHERE (em.first_name != eu.first_name 
    OR em.last_name != eu.last_name 
    OR em.department != eu.department 
    OR em.salary != eu.salary 
    OR em.status != eu.status);

-- Step 2: Insert new records
INSERT INTO employees_master (employee_id, first_name, last_name, email, department, salary, status, hire_date)
SELECT 
    eu.employee_id,
    eu.first_name,
    eu.last_name,
    eu.email,
    eu.department,
    eu.salary,
    eu.status,
    CURDATE()
FROM employee_updates eu
LEFT JOIN employees_master em ON eu.employee_id = em.employee_id
WHERE em.employee_id IS NULL;

-- Log inserts to audit table
INSERT INTO merge_audit_log (employee_id, action_type, new_values)
SELECT 
    eu.employee_id,
    'INSERT',
    JSON_OBJECT(
        'first_name', eu.first_name,
        'last_name', eu.last_name,
        'email', eu.email,
        'department', eu.department,
        'salary', eu.salary,
        'status', eu.status
    )
FROM employee_updates eu
LEFT JOIN employees_master em ON eu.employee_id = em.employee_id
WHERE em.employee_id IS NULL;

-- Step 3: Handle records that exist in target but not in source (optional delete)
-- Mark as inactive instead of deleting
UPDATE employees_master em
SET status = 'Inactive'
WHERE em.employee_id NOT IN (SELECT employee_id FROM employee_updates)
AND em.status = 'Active';

COMMIT;

-- =============================================================================
-- METHOD 2: STORED PROCEDURE FOR MERGE OPERATION
-- =============================================================================

DELIMITER //

CREATE PROCEDURE sp_merge_employees()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_employee_id VARCHAR(10);
    DECLARE v_first_name VARCHAR(50);
    DECLARE v_last_name VARCHAR(50);
    DECLARE v_email VARCHAR(100);
    DECLARE v_department VARCHAR(50);
    DECLARE v_salary DECIMAL(10,2);
    DECLARE v_status VARCHAR(20);
    
    -- Cursor for employee updates
    DECLARE cur CURSOR FOR 
        SELECT employee_id, first_name, last_name, email, department, salary, status 
        FROM employee_updates;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    -- Error handling
[I    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    OPEN cur;
    
    read_loop: LOOP
        FETCH cur INTO v_employee_id, v_first_name, v_last_name, v_email, v_department, v_salary, v_status;
        
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        -- Try to update existing record
        UPDATE employees_master 
        SET 
            first_name = v_first_name,
            last_name = v_last_name,
            email = v_email,
            department = v_department,
            salary = v_salary,
            status = v_status,
            updated_at = CURRENT_TIMESTAMP
        WHERE employee_id = v_employee_id;
        
        -- If no rows affected, insert new record
        IF ROW_COUNT() = 0 THEN
            INSERT INTO employees_master (employee_id, first_name, last_name, email, department, salary, status, hire_date)
            VALUES (v_employee_id, v_first_name, v_last_name, v_email, v_department, v_salary, v_status, CURDATE());
        END IF;
        
    END LOOP;
    
    CLOSE cur;
    COMMIT;
    
    -- Return summary
    SELECT 
        'Merge completed' as status,
        (SELECT COUNT(*) FROM employees_master) as total_employees,
        (SELECT COUNT(*) FROM merge_audit_log WHERE merge_timestamp >= DATE_SUB(NOW(), INTERVAL 1 MINUTE)) as changes_logged;
        
END //

DELIMITER ;

-- Execute the merge procedure
-- CALL sp_merge_employees();

-- =============================================================================
-- METHOD 3: CONDITIONAL MERGE WITH BUSINESS RULES
-- =============================================================================

-- Create a more complex merge with business logic
START TRANSACTION;

-- Create temporary table for merge processing
CREATE TEMPORARY TABLE temp_merge_results (
    employee_id VARCHAR(10),
    action_required ENUM('INSERT', 'UPDATE', 'NO_CHANGE', 'CONFLICT'),
    conflict_reason VARCHAR(255),
    old_salary DECIMAL(10,2),
    new_salary DECIMAL(10,2)
);

-- Analyze what actions are needed
INSERT INTO temp_merge_results (employee_id, action_required, conflict_reason, old_salary, new_salary)
SELECT 
    eu.employee_id,
    CASE 
        WHEN em.employee_id IS NULL THEN 'INSERT'
        WHEN em.salary > eu.salary AND em.status = 'Active' THEN 'CONFLICT'
        WHEN (em.first_name != eu.first_name OR em.last_name != eu.last_name OR 
              em.department != eu.department OR em.salary != eu.salary OR 
              em.status != eu.status) THEN 'UPDATE'
        ELSE 'NO_CHANGE'
    END as action_required,
    CASE 
        WHEN em.salary > eu.salary AND em.status = 'Active' 
        THEN 'Salary decrease detected - requires manual review'
        ELSE NULL
    END as conflict_reason,
    em.salary,
    eu.salary
FROM employee_updates eu
LEFT JOIN employees_master em ON eu.employee_id = em.employee_id;

-- Show conflicts for manual review
SELECT 
    employee_id,
    conflict_reason,
    old_salary,
    new_salary
FROM temp_merge_results 
WHERE action_required = 'CONFLICT';

-- Perform safe updates (non-conflicting changes only)
UPDATE employees_master em
INNER JOIN employee_updates eu ON em.employee_id = eu.employee_id
INNER JOIN temp_merge_results tmr ON eu.employee_id = tmr.employee_id
SET 
    em.first_name = eu.first_name,
    em.last_name = eu.last_name,
    em.email = eu.email,
    em.department = eu.department,
    em.salary = eu.salary,
    em.status = eu.status,
    em.updated_at = CURRENT_TIMESTAMP
WHERE tmr.action_required = 'UPDATE';

-- Insert new employees
INSERT INTO employees_master (employee_id, first_name, last_name, email, department, salary, status, hire_date)
SELECT 
    eu.employee_id,
    eu.first_name,
    eu.last_name,
    eu.email,
    eu.department,
    eu.salary,
    eu.status,
    CURDATE()
FROM employee_updates eu
INNER JOIN temp_merge_results tmr ON eu.employee_id = tmr.employee_id
WHERE tmr.action_required = 'INSERT';

COMMIT;

-- =============================================================================
-- METHOD 4: MERGE WITH DATA VALIDATION
-- =============================================================================

-- Create validation rules table
CREATE TABLE IF NOT EXISTS validation_rules (
    rule_name VARCHAR(50) PRIMARY KEY,
    rule_description TEXT,
    min_value DECIMAL(10,2),
    max_value DECIMAL(10,2),
    allowed_values TEXT,
    is_active BOOLEAN DEFAULT TRUE
);

-- Insert validation rules
INSERT IGNORE INTO validation_rules (rule_name, rule_description, min_value, max_value, allowed_values)
VALUES 
    ('salary_range', 'Valid salary range', 30000.00, 200000.00, NULL),
    ('valid_departments', 'Allowed departments', NULL, NULL, 'Engineering,Marketing,Sales,HR,Finance,IT'),
    ('valid_status', 'Allowed status values', NULL, NULL, 'Active,Inactive,Terminated');

-- Validated merge procedure
DELIMITER //

CREATE PROCEDURE sp_validated_merge()
BEGIN
    DECLARE validation_errors INT DEFAULT 0;
    
    -- Error handling
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Create validation results table
    CREATE TEMPORARY TABLE validation_results (
        employee_id VARCHAR(10),
        error_type VARCHAR(50),
        error_message TEXT
    );
    
    -- Validate salary range
    INSERT INTO validation_results (employee_id, error_type, error_message)
    SELECT 
        eu.employee_id,
        'SALARY_VALIDATION',
        CONCAT('Salary ', eu.salary, ' is outside valid range (30000-200000)')
    FROM employee_updates eu
    WHERE eu.salary < 30000 OR eu.salary > 200000;
    
    -- Validate departments
    INSERT INTO validation_results (employee_id, error_type, error_message)
    SELECT 
        eu.employee_id,
        'DEPARTMENT_VALIDATION',
        CONCAT('Department "', eu.department, '" is not in allowed list')
    FROM employee_updates eu
    WHERE FIND_IN_SET(eu.department, 'Engineering,Marketing,Sales,HR,Finance,IT') = 0;
    
    -- Validate status
    INSERT INTO validation_results (employee_id, error_type, error_message)
    SELECT 
        eu.employee_id,
        'STATUS_VALIDATION',
        CONCAT('Status "', eu.status, '" is not valid')
    FROM employee_updates eu
    WHERE FIND_IN_SET(eu.status, 'Active,Inactive,Terminated') = 0;
    
    -- Check if there are validation errors
    SELECT COUNT(*) INTO validation_errors FROM validation_results;
    
    IF validation_errors > 0 THEN
        -- Return validation errors
        SELECT * FROM validation_results;
        ROLLBACK;
    ELSE
        -- Proceed with merge if validation passes
        -- Update existing records
        UPDATE employees_master em
        INNER JOIN employee_updates eu ON em.employee_id = eu.employee_id
        SET 
            em.first_name = eu.first_name,
            em.last_name = eu.last_name,
            em.email = eu.email,
            em.department = eu.department,
            em.salary = eu.salary,
            em.status = eu.status,
            em.updated_at = CURRENT_TIMESTAMP;
        
        -- Insert new records
        INSERT INTO employees_master (employee_id, first_name, last_name, email, department, salary, status, hire_date)
        SELECT 
            eu.employee_id,
            eu.first_name,
            eu.last_name,
            eu.email,
            eu.department,
            eu.salary,
            eu.status,
            CURDATE()
        FROM employee_updates eu
        LEFT JOIN employees_master em ON eu.employee_id = em.employee_id
        WHERE em.employee_id IS NULL;
        
        COMMIT;
        
        -- Return success message
        SELECT 'Merge completed successfully' as status, ROW_COUNT() as records_processed;
    END IF;
    
END //

DELIMITER ;

-- =============================================================================
-- METHOD 5: INCREMENTAL MERGE (Delta Processing)
-- =============================================================================

-- Add tracking columns for incremental processing
ALTER TABLE employee_updates ADD COLUMN IF NOT EXISTS processed BOOLEAN DEFAULT FALSE;
ALTER TABLE employee_updates ADD COLUMN IF NOT EXISTS process_date TIMESTAMP NULL;

-- Mark some records as already processed
UPDATE employee_updates SET processed = TRUE, process_date = DATE_SUB(NOW(), INTERVAL 1 DAY) 
WHERE employee_id IN ('EMP001', 'EMP002');

-- Process only unprocessed records
START TRANSACTION;

-- Identify and process delta records
CREATE TEMPORARY TABLE delta_records AS
SELECT * FROM employee_updates 
WHERE processed = FALSE OR process_date IS NULL;

-- Show what will be processed
SELECT 
    COUNT(*) as delta_count,
    GROUP_CONCAT(employee_id) as employee_ids
FROM delta_records;

-- Perform merge on delta records only
UPDATE employees_master em
INNER JOIN delta_records dr ON em.employee_id = dr.employee_id
SET 
    em.first_name = dr.first_name,
    em.last_name = dr.last_name,
    em.email = dr.email,
    em.department = dr.department,
    em.salary = dr.salary,
    em.status = dr.status,
    em.updated_at = CURRENT_TIMESTAMP;

INSERT INTO employees_master (employee_id, first_name, last_name, email, department, salary, status, hire_date)
SELECT 
    dr.employee_id,
    dr.first_name,
    dr.last_name,
    dr.email,
    dr.department,
    dr.salary,
    dr.status,
    CURDATE()
FROM delta_records dr
LEFT JOIN employees_master em ON dr.employee_id = em.employee_id
WHERE em.employee_id IS NULL;

-- Mark processed records
UPDATE employee_updates 
SET processed = TRUE, process_date = NOW() 
WHERE employee_id IN (SELECT employee_id FROM delta_records);

COMMIT;

-- =============================================================================
-- VERIFICATION AND REPORTING
-- =============================================================================

-- Summary report of merge results
SELECT 
    'Total Employees' as metric,
    COUNT(*) as count
FROM employees_master
UNION ALL
SELECT 
    'Active Employees',
    COUNT(*)
FROM employees_master 
WHERE status = 'Active'
UNION ALL
SELECT 
    'Recent Updates (last hour)',
    COUNT(*)
FROM employees_master 
WHERE updated_at > DATE_SUB(NOW(), INTERVAL 1 HOUR)
UNION ALL
SELECT 
    'Audit Log Entries',
    COUNT(*)
FROM merge_audit_log;

-- Detailed change report
SELECT 
    mal.employee_id,
    mal.action_type,
    mal.merge_timestamp,
    CASE 
        WHEN mal.action_type = 'UPDATE' THEN 
            CONCAT('Changed from: ', JSON_UNQUOTE(JSON_EXTRACT(mal.old_values, '$.salary')), 
                   ' to: ', JSON_UNQUOTE(JSON_EXTRACT(mal.new_values, '$.salary')))
        WHEN mal.action_type = 'INSERT' THEN 
            CONCAT('New employee: ', JSON_UNQUOTE(JSON_EXTRACT(mal.new_values, '$.first_name')), 
                   ' ', JSON_UNQUOTE(JSON_EXTRACT(mal.new_values, '$.last_name')))
        ELSE mal.action_type
    END as change_description
FROM merge_audit_log mal
ORDER BY mal.merge_timestamp DESC
LIMIT 10;

-- =============================================================================
-- CLEANUP
-- =============================================================================

-- Drop temporary tables
DROP TEMPORARY TABLE IF EXISTS temp_merge_results;
DROP TEMPORARY TABLE IF EXISTS delta_records;

-- Drop procedures (uncomment if needed)
-- DROP PROCEDURE IF EXISTS sp_merge_employees;
-- DROP PROCEDURE IF EXISTS sp_validated_merge;

-- =============================================================================
-- BEST PRACTICES SUMMARY
-- =============================================================================

/*
MERGE OPERATION BEST PRACTICES:

1. UNDERSTAND YOUR DATABASE SYSTEM
   - SQL Server: Native MERGE statement
   - PostgreSQL: INSERT ... ON CONFLICT or MERGE (v15+)
   - MySQL: Simulate with INSERT ... ON DUPLICATE KEY UPDATE
   - Oracle: MERGE statement with WHEN MATCHED/NOT MATCHED

2. PLAN YOUR MERGE STRATEGY
   - Identify source and target tables
   - Define matching criteria (usually primary/unique keys)
   - Determine actions: INSERT, UPDATE, DELETE
   - Handle conflicts and exceptions

3. IMPLEMENT PROPER VALIDATION
   - Validate data before merge operations
   - Check business rules and constraints
   - Handle data type conversions
   - Verify referential integrity

4. USE TRANSACTIONS
   - Wrap merge operations in transactions
   - Implement proper error handling
   - Plan for rollback scenarios
   - Test with small datasets first

5. PERFORMANCE OPTIMIZATION
   - Use appropriate indexes on matching columns
   - Consider batch processing for large datasets
   - Monitor execution plans
   - Use staging tables for complex transformations

6. AUDIT AND MONITORING
   - Log all merge operations
   - Track changes with audit tables
   - Monitor data quality after merges
   - Implement alerting for anomalies

7. INCREMENTAL PROCESSING
   - Process only changed records when possible
   - Use timestamps or version numbers
   - Implement change data capture (CDC)
   - Schedule regular merge jobs

8. CONFLICT RESOLUTION
   - Define clear rules for handling conflicts
   - Implement manual review processes for complex cases
   - Use business logic to resolve automatically where possible
   - Document conflict resolution procedures

9. TESTING AND VALIDATION
   - Test merge logic thoroughly
   - Validate results after operations
   - Compare record counts and checksums
   - Test error scenarios and edge cases

10. DOCUMENTATION
    - Document merge procedures and business rules
    - Maintain change logs
    - Create runbooks for operational procedures
    - Train team members on merge processes
*/

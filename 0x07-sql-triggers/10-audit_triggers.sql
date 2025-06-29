-- Filename: 10-audit_triggers.sql
-- Topic: Audit Triggers
-- Description: This script demonstrates the use of triggers for auditing purposes.

-- Step 1: Create the main table
CREATE TABLE employees (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    position VARCHAR(100) NOT NULL,
    salary DECIMAL(10, 2) NOT NULL
);

-- Step 2: Create the audit table
CREATE TABLE employees_audit (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    employee_id INT NOT NULL,
    operation VARCHAR(10) NOT NULL,
    old_name VARCHAR(100),
    new_name VARCHAR(100),
    old_position VARCHAR(100),
    new_position VARCHAR(100),
    old_salary DECIMAL(10, 2),
    new_salary DECIMAL(10, 2),
    log_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Step 3: Create the INSERT trigger
DELIMITER $$

CREATE TRIGGER after_insert_employee
AFTER INSERT ON employees
FOR EACH ROW
BEGIN
    INSERT INTO employees_audit (
        employee_id,
        operation,
        new_name,
        new_position,
        new_salary
    )
    VALUES (
        NEW.id,
        'INSERT',
        NEW.name,
        NEW.position,
        NEW.salary
    );
END$$

DELIMITER ;

-- Step 4: Create the UPDATE trigger
DELIMITER $$

CREATE TRIGGER after_update_employee
AFTER UPDATE ON employees
FOR EACH ROW
BEGIN
    INSERT INTO employees_audit (
        employee_id,
        operation,
        old_name,
        new_name,
        old_position,
        new_position,
        old_salary,
        new_salary
    )
    VALUES (
        OLD.id,
        'UPDATE',
        OLD.name,
        NEW.name,
        OLD.position,
        NEW.position,
        OLD.salary,
        NEW.salary
    );
END$$

DELIMITER ;

-- Step 5: Create the DELETE trigger
DELIMITER $$

CREATE TRIGGER after_delete_employee
AFTER DELETE ON employees
FOR EACH ROW
BEGIN
    INSERT INTO employees_audit (
        employee_id,
        operation,
        old_name,
        old_position,
        old_salary
    )
    VALUES (
        OLD.id,
        'DELETE',
        OLD.name,
        OLD.position,
        OLD.salary
    );
END$$

DELIMITER ;

-- Step 6: Test the triggers
-- Insert a new employee
INSERT INTO employees (name, position, salary)
VALUES ('Jane Smith', 'Engineer', 60000.00);

-- Update the employee's salary
UPDATE employees
SET salary = 65000.00
WHERE name = 'Jane Smith';

-- Delete the employee
DELETE FROM employees
WHERE name = 'Jane Smith';

-- Check the audit log
SELECT * FROM employees_audit;

-- Step 7: Clean up
DROP TABLE employees_audit;
DROP TABLE employees;

-- 0-basic_triggers.sql
-- This script demonstrates the basic syntax of creating a trigger in SQL

-- STEP 1: Create a sample table
CREATE TABLE employees (
    id INT PRIMARY KEY,
    name VARCHAR(100),
    salary DECIMAL(10, 2)
);

CREATE TABLE log_table (
    log_id SERIAL PRIMARY KEY,
    message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- STEP 2: Create a basic AFTER INSERT trigger
DELIMITER //
CREATE TRIGGER trg_after_insert_employee
AFTER INSERT ON employees
FOR EACH ROW
BEGIN
    INSERT INTO log_table (message) 
    VALUES (CONCAT('Inserted employee with ID: ', NEW.id));
END;//
DELIMITER ;

-- STEP 3: Test the trigger
INSERT INTO employees (id, name, salary) VALUES (1, 'Alice', 5000.00);

-- Check the log_table for output
SELECT * FROM log_table;



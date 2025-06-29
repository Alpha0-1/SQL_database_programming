/*
 * Filename: 12-data_validation.sql
 * Description: Demonstrates various data validation techniques in SQL
 */

/*
 * Table Setup: Create a sample table with constraints
 * This table will enforce validation at the database level
 */
USE your_database_name;

-- Drop existing table if it exists
DROP TABLE IF EXISTS employee_validations;

-- Create a new table with constraints
CREATE TABLE employee_validations (
    employee_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL CHECK (first_name != ''),  -- Non-empty check
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,                       -- Unique email constraint
    phone_number VARCHAR(15) CHECK (phone_number LIKE '+%'),  -- Format check for international numbers
    salary DECIMAL(10,2) CHECK (salary > 0),                  -- Positive salary check
    hire_date DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

/*
 * Section 1: Basic Data Validation with CHECK Constraints
 */
-- Insert valid data
INSERT INTO employee_validations (first_name, last_name, email, phone_number, salary, hire_date)
VALUES
('John', 'Doe', 'john.doe@example.com', '+1234567890', 50000.00, '2023-01-01');

-- Attempt invalid data (should fail)
-- The CHECK constraint for phone_number enforces the '+' prefix
-- INSERT INTO employee_validations (first_name, last_name, email, phone_number, salary, hire_date)
-- VALUES ('Jane', 'Smith', 'jane.smith@example.com', '1234567890', 60000.00, '2023-01-02');

/*
 * Section 2: UNIQUE Constraints for Data Uniqueness
 */
-- Insert duplicate email (should fail)
-- INSERT INTO employee_validations (first_name, last_name, email, phone_number, salary, hire_date)
-- VALUES ('Mike', 'Johnson', 'john.doe@example.com', '+0987654321', 55000.00, '2023-01-03');

/*
 * Section 3: Using TRIGGERS for Validation
 */
-- Create a trigger to validate data before insertion
DELIMITER $$
CREATE TRIGGER validate_employee_data
BEFORE INSERT ON employee_validations
FOR EACH ROW
BEGIN
    -- Validate email format
    IF NEW.email NOT LIKE '%@%.%' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid email format';
    END IF;

    -- Ensure salary is within reasonable limits
    IF NEW.salary < 10000.00 OR NEW.salary > 100000.00 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Salary must be between 10,000 and 100,000';
    END IF;
END$$
DELIMITER ;

-- Insert valid data (should pass)
INSERT INTO employee_validations (first_name, last_name, email, phone_number, salary, hire_date)
VALUES
('Jane', 'Smith', 'jane.smith@example.com', '+0987654321', 60000.00, '2023-01-02');

-- Attempt invalid data (should fail)
-- INSERT INTO employee_validations (first_name, last_name, email, phone_number, salary, hire_date)
-- VALUES ('Mike', 'Johnson', 'invalid_email', '+1234567890', 5000.00, '2023-01-03');

/*
 * Section 4: Data Validation Using Stored Procedures
 */
DELIMITER $$
CREATE PROCEDURE insert_employee(
    IN p_first_name VARCHAR(50),
    IN p_last_name VARCHAR(50),
    IN p_email VARCHAR(100),
    IN p_phone_number VARCHAR(15),
    IN p_salary DECIMAL(10,2),
    IN p_hire_date DATE
)
BEGIN
    DECLARE error_message VARCHAR(255);
    
    -- Check if email is valid
    IF p_email NOT LIKE '%@%.%' THEN
        SET error_message = 'Invalid email format';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = error_message;
    END IF;

    -- Check salary range
    IF p_salary < 10000.00 OR p_salary > 100000.00 THEN
        SET error_message = 'Salary must be between 10,000 and 100,000';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = error_message;
    END IF;

    -- Insert data if validation passes
    INSERT INTO employee_validations (first_name, last_name, email, phone_number, salary, hire_date)
    VALUES (p_first_name, p_last_name, p_email, p_phone_number, p_salary, p_hire_date);
END$$
DELIMITER ;

-- CALL the stored procedure with valid data
CALL insert_employee('Mike', 'Johnson', 'mike.johnson@example.com', '+1234567890', 75000.00, '2023-01-03');

-- CALL the stored procedure with invalid data (should fail)
-- CALL insert_employee('Sarah', 'Lee', 'invalid_email', '+0987654321', 5000.00, '2023-01-04');

/*
 * Section 5: Data Validation Using CHECK Constraints
 */
-- Check existing data against constraints
SELECT *
FROM employee_validations
WHERE salary <= 0;  -- Should return no rows due to CHECK constraint

/*
 * Section 6: Data Validation Using Stored Functions
 */
DELIMITER $$
CREATE FUNCTION validate_phone_number(phone VARCHAR(15)) 
RETURNS BOOLEAN
DETERMINISTIC
BEGIN
    -- Validate international phone number format (e.g., +1234567890)
    RETURN phone LIKE '+%' AND LENGTH(phone) = 13;
END$$
DELIMITER ;

-- Use the function in a query
SELECT *, validate_phone_number(phone_number) AS is_valid_phone
FROM employee_validations;

-- Attempt invalid phone number (should return false)
-- INSERT INTO employee_validations (first_name, last_name, email, phone_number, salary, hire_date)
-- VALUES ('Anna', 'Bell', 'anna.bell@example.com', '1234567890', 80000.00, '2023-01-05');

/*
 * Section 7: Transaction and Error Handling
 */
START TRANSACTION;
    -- Attempt to insert invalid data (should trigger error)
    -- INSERT INTO employee_validations (first_name, last_name, email, phone_number, salary, hire_date)
    -- VALUES ('Test', 'Error', 'invalid@example', '12345', 0.00, '2023-01-05');

    -- If error occurs, rollback
    ROLLBACK;

-- Check the table after rollback
SELECT * FROM employee_validations;

/*
 * Cleanup: Drop the table and stored procedures/functions
 */
DROP TABLE IF EXISTS employee_validations;
DROP PROCEDURE IF EXISTS insert_employee;
DROP FUNCTION IF EXISTS validate_phone_number;

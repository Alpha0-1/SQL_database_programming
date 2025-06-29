/*
 * Filename: 101-data_migration.sql
 * Description: Demonstrates data migration between databases with schema transformation
 */

/*
 * Step 1: Setup - Create Source and Target Tables
 */

-- Create source database and table if not exists
DROP DATABASE IF EXISTS source_db;
CREATE DATABASE source_db;

USE source_db;

DROP TABLE IF EXISTS employees_source;
CREATE TABLE employees_source (
    employee_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    phone VARCHAR(15),
    salary DECIMAL(10,2),
    hire_date DATE
);

-- Populate source table with sample data
INSERT INTO employees_source (first_name, last_name, email, phone, salary, hire_date)
VALUES
('John', 'Doe', 'john.doe@example.com', '1234567890', 50000.00, '2020-01-15'),
('Jane', 'Smith', 'jane.smith@example.com', '0987654321', 60000.00, '2019-03-22'),
('Mike', 'Johnson', 'mike.johnson@example.com', '4567891230', 75000.00, '2021-07-05');

-- Create target database and table with different schema
DROP DATABASE IF EXISTS target_db;
CREATE DATABASE target_db;

USE target_db;

DROP TABLE IF EXISTS employees_target;
CREATE TABLE employees_target (
    id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(100),
    email_address VARCHAR(100),
    phone_number VARCHAR(15),
    monthly_income DECIMAL(10,2),
    start_date DATE,
    status ENUM('active', 'inactive') DEFAULT 'active'
);

/*
 * Step 2: Data Transformation and Migration Using Stored Procedure
 */

DELIMITER $$

USE target_db;

-- Create a stored procedure for data migration
DROP PROCEDURE IF EXISTS migrate_data$$
CREATE PROCEDURE migrate_data()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    -- Log table to track migration progress and errors
    DROP TABLE IF EXISTS migration_log;
    CREATE TABLE migration_log (
        log_id INT AUTO_INCREMENT PRIMARY KEY,
        employee_id INT,
        status VARCHAR(20),
        error_message VARCHAR(255),
        timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    -- Cursor to iterate over source data
    DECLARE cur CURSOR FOR
        SELECT employee_id, first_name, last_name, email, phone, salary, hire_date
        FROM source_db.employees_source;

    -- Transaction for atomicity
    START TRANSACTION;

    OPEN cur;

    read_loop: LOOP
        FETCH cur INTO
            @emp_id, @fname, @lname, @email, @phone, @salary, @hire_date;

        IF done THEN
            LEAVE read_loop;
        END IF;

        -- Data transformation
        SET @full_name = CONCAT(@fname, ' ', @ lname);  -- Combine first and last name
        SET @monthly_income = @salary;                  -- Direct mapping
        SET @start_date = @hire_date;                   -- Direct mapping
        SET @phone_number = CONCAT('+', @phone);        -- Format phone number

        -- Insert transformed data into target table
        INSERT INTO employees_target
        (full_name, email_address, phone_number, monthly_income, start_date)
        VALUES
        (@full_name, @email, @phone_number, @monthly_income, @start_date);

        -- Log successful insertion
        INSERT INTO migration_log (employee_id, status)
        VALUES (@emp_id, 'SUCCESS');

    END LOOP read_loop;

    CLOSE cur;

    -- Check for any errors during the process
    -- (In practice, more comprehensive error checking would be implemented)

    -- Commit the transaction
    COMMIT;

    -- Optional: Send completion notification
    SELECT 'Data migration completed successfully.' AS status;

END$$
DELIMITER ;

/*
 * Step 3: Execute the Migration
 */

USE target_db;
CALL migrate_data();

/*
 * Step 4: Validate the Migration
 */

-- Verify all data has been migrated
SELECT COUNT(*) AS source_count FROM source_db.employees_source;
SELECT COUNT(*) AS target_count FROM target_db.employees_target;

-- Check for any errors in the log
SELECT * FROM target_db.migration_log WHERE status = 'ERROR';

/*
 * Step 5: Cleanup
 */

-- Drop temporary tables and stored procedures
USE target_db;
DROP TABLE IF EXISTS migration_log;
DROP PROCEDURE IF EXISTS migrate_data;

USE source_db;
DROP TABLE IF EXISTS employees_source;

DROP DATABASE IF EXISTS source_db;
DROP DATABASE IF EXISTS target_db;

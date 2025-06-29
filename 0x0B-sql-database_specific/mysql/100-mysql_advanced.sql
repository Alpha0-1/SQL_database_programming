-- Advanced MySQL Features: Stored Procedures & Triggers

-- Stored Procedure Example
DELIMITER //
CREATE PROCEDURE GetEmployeeCount()
BEGIN
    SELECT COUNT(*) AS total_employees FROM employees;
END //
DELIMITER ;

-- Call the procedure
CALL GetEmployeeCount();

-- Trigger Example: Log changes to employee table
CREATE TABLE employee_audit (
    audit_id INT AUTO_INCREMENT PRIMARY KEY,
    old_email VARCHAR(100),
    new_email VARCHAR(100),
    change_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DELIMITER //
CREATE TRIGGER after_employee_update
AFTER UPDATE ON employees
FOR EACH ROW
BEGIN
    IF OLD.email <> NEW.email THEN
        INSERT INTO employee_audit (old_email, new_email)
        VALUES (OLD.email, NEW.email);
    END IF;
END //
DELIMITER ;

-- 0-basic_procedure.sql
-- Purpose: Demonstrates creation and execution of a basic stored procedure

-- Create a simple stored procedure that retrieves all employees
CREATE PROCEDURE GetAllEmployees()
BEGIN
    SELECT * FROM Employees;
END;

-- Example usage:
-- CALL GetAllEmployees();

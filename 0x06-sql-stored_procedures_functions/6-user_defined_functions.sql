/*
  Filename: 6-user_defined_functions.sql
  Description: Demonstrate the creation and usage of a basic user-defined function.
  
  Function Name: dbo.ufn_GetAverageSalary
  Purpose: This function calculates the average salary of employees in a given department.
  
  Parameters:
    @DepartmentID INT - The ID of the department for which to calculate the average salary.
  
  Returns:
    DECIMAL(18, 2) - The average salary of employees in the specified department.
*/

USE AdventureWorks;
GO

-- Drop the function if it exists
IF OBJECT_ID('dbo.ufn_GetAverageSalary', 'FN') IS NOT NULL
    DROP FUNCTION dbo.ufn_GetAverageSalary;
GO

-- Create the user-defined function
CREATE FUNCTION dbo.ufn_GetAverageSalary
(
    @DepartmentID INT
)
RETURNS DECIMAL(18, 2)
AS
BEGIN
    -- Declare a variable to hold the average salary
    DECLARE @AverageSalary DECIMAL(18, 2);
    
    -- Calculate the average salary for the specified department
    SELECT @AverageSalary = AVG(Salary)
    FROM HumanResources.Employee
    WHERE DepartmentID = @DepartmentID
    HAVING COUNT(EmployeeID) > 0;  -- Ensure there are employees in the department
    
    -- Return the calculated average salary
    RETURN @AverageSalary;
END;
GO

-- Example usage:
-- To use the function, simply call it with the desired DepartmentID
SELECT dbo.ufn_GetAverageSalary(1) AS AverageSalary;

-- To handle cases where no employees are found in the department
-- We can use a DEFAULT constraint or add additional error handling
-- For example:
SELECT COALESCE(dbo.ufn_GetAverageSalary(99), 0) AS AverageSalary;

-- Error Handling Example
GO
CREATE PROCEDURE dbousp_GetAverageSalary
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SELECT dbo.ufn_GetAverageSalary(1) AS AverageSalary;
    END TRY
    BEGIN CATCH
        SELECT 
            ERROR_NUMBER() AS ErrorNumber,
            ERROR_MESSAGE() AS ErrorMessage,
            ERROR_SEVERITY() AS ErrorSeverity,
            ERROR_STATE() AS ErrorState,
            ERROR_PROCEDURE() AS ErrorProcedure,
            ERROR_LINE() AS ErrorLine,
            GETDATE() AS ErrorDateTime;
        -- Return an error result
        RETURN -1;
    END CATCH;
END;
GO

-- Execute the procedure
EXEC dbousp_GetAverageSalary;
GO

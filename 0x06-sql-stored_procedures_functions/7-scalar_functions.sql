/*
  Filename: 7-scalar_functions.sql
  Description: Demonstrate the creation and usage of scalar functions.
  
  Scalar Function Name: dbo.ufn_GetFullEmployeeName
  Purpose: This function concatenates the first name, middle initial, and last name of an employee to form a full name.

  Parameters:
    @FirstName VARCHAR(50) - The first name of the employee.
    @MiddleInitial CHAR(1)  - The middle initial of the employee.
    @LastName VARCHAR(50)   - The last name of the employee.

  Returns:
    VARCHAR(150) - The concatenated full name of the employee.

  Example Usage:
    SELECT dbo.ufn_GetFullEmployeeName('John', 'D', 'Doe') AS FullName;
*/

USE AdventureWorks;
GO

-- Drop the function if it exists
IF OBJECT_ID('dbo.ufn_GetFullEmployeeName', 'FN') IS NOT NULL
    DROP FUNCTION dbo.ufn_GetFullEmployeeName;
GO

-- Create the scalar function
CREATE FUNCTION dbo.ufn_GetFullEmployeeName
(
    @FirstName VARCHAR(50),
    @MiddleInitial CHAR(1),
    @LastName VARCHAR(50)
)
RETURNS VARCHAR(150)
AS
BEGIN
    -- Concatenate the names with appropriate formatting
    RETURN @FirstName + ' ' + @MiddleInitial + '. ' + @LastName;
END;
GO

-- Example usage
SELECT dbo.ufn_GetFullEmployeeName('John', 'D', 'Doe') AS FullName;

/*
  Filename: 9-recursive_functions.sql
  Description: Demonstrate the creation and usage of recursive functions.
  
  Recursive Function Name: dbo.ufn_Factorial
  Purpose: This function calculates the factorial of a given number using recursion.

  Parameters:
    @Number INT - The number to calculate the factorial for.

  Returns:
    BIGINT - The factorial of the input number.

  Example Usage:
    SELECT dbo.ufn_Factorial(5) AS Factorial;
*/

USE AdventureWorks;
GO

-- Drop the function if it exists
IF OBJECT_ID('dbo.ufn_Factorial', 'FN') IS NOT NULL
    DROP FUNCTION dbo.ufn_Factorial;
GO

-- Create the recursive function
CREATE FUNCTION dbo.ufn_Factorial
(
    @Number INT
)
RETURNS BIGINT
AS
BEGIN
    -- Base case to terminate recursion
    IF @Number <= 1
        RETURN 1;
    ELSE
        -- Recursive call
        RETURN @Number * dbo.ufn_Factorial(@Number - 1);
END;
GO

-- Example usage
SELECT dbo.ufn_Factorial(5) AS Factorial;

/*
  Filename: 2-procedure_variables.sql
  Description: Demonstrate the use of local variables within a stored procedure.
  
  Parameters:
    None
  
  Example Usage:
    EXECUTE dbo.usp_VariablesExample;
*/

USE YourDatabase;
GO

IF OBJECT_ID('dbo.usp_VariablesExample', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_VariablesExample;
GO

CREATE PROCEDURE dbo.usp_VariablesExample
AS
BEGIN
    -- Set up error handling
    SET NOCOUNT ON;
    
    -- Declare variables
    DECLARE @Counter INT,
            @Message VARCHAR(100);
            
    -- Initialize variables
    SET @Counter = 0;
    SET @Message = 'Variable Demonstration';
    
    -- Example logic using variables
    WHILE @Counter < 3
    BEGIN
        SET @Counter = @Counter + 1;
        PRINT @Message + ' - ' + CONVERT(VARCHAR, @Counter);
    END;
END;
GO

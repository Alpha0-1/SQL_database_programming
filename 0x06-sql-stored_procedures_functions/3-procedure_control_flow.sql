/*
  Filename: 3-procedure_control_flow.sql
  Description: Demonstrate IF, WHILE, and LOOP statements in a stored procedure.
  
  Parameters:
    None
  
  Example Usage:
    EXECUTE dbo.usp_ControlFlowExample;
*/

USE YourDatabase;
GO

IF OBJECT_ID('dbo.usp_ControlFlowExample', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_ControlFlowExample;
GO

CREATE PROCEDURE dbo.usp_ControlFlowExample
AS
BEGIN
    -- Set up error handling
    SET NOCOUNT ON;
    
    -- Declare variables
    DECLARE @Number INT;
    SET @Number = 10;
    
    -- Example with IF statement
    IF @Number > 5
    BEGIN
        PRINT 'Number is greater than 5.';
    END;
    ELSE
    BEGIN
        PRINT 'Number is 5 or less.';
    END;
    
    -- Example with WHILE loop
    WHILE @Number > 0
    BEGIN
        PRINT 'Counting down: ' + CONVERT(VARCHAR, @Number);
        SET @Number = @Number - 1;
    END;
END;
GO

/*
  Filename: 12-procedure_debugging.sql
  Description: Demonstrate debugging techniques for stored procedures.
  
  Stored Procedure Name: dbo.usp_DebugExample
  Purpose: This procedure provides an example of debugging techniques, including PRINT statements and error handling.

  Parameters:
    @Input INT - An example input parameter.

  Returns:
    No return value, demonstrates debugging techniques.

  Example Usage:
    -- Debugging example
    EXECUTE dbo.usp_DebugExample 10;
*/

USE AdventureWorks;
GO

-- Drop the procedure if it exists
IF OBJECT_ID('dbo.usp_DebugExample', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_DebugExample;
GO

-- Create the stored procedure with debugging techniques
CREATE PROCEDURE dbo.usp_DebugExample
(
    @Input INT
)
AS
BEGIN
    -- Debugging flag for PRINT statements
    DECLARE @EnableDebug BIT = 1;
    
    -- Control flow variable
    DECLARE @Result INT;
    
    -- Debug: Print parameter value
    IF @EnableDebug = 1
        PRINT 'Procedure starting with input: ' + CONVERT(VARCHAR, @Input);
    
    -- Error handling with try-catch
    BEGIN TRY
        -- Example logic
        SET @Result = @Input * 2;
        
        -- Debug: Print intermediate result
        IF @EnableDebug = 1
            PRINT 'Intermediate result: ' + CONVERT(VARCHAR, @Result);
        
        -- Simulate an error
        IF @Input > 5
            RAISERROR('Input value exceeds allowed limit.', 16, 1);
        
        -- Continue with logic
        SET @Result = @Result + 10;
        
        -- Debug: Print final result
        IF @EnableDebug = 1
            PRINT 'Final result: ' + CONVERT(VARCHAR, @Result);
    END TRY
    BEGIN CATCH
        -- Debug: Print error details
        PRINT 'Error occurred: ' + ERROR_MESSAGE();
        PRINT 'Error number: ' + CONVERT(VARCHAR, ERROR_NUMBER());
        PRINT 'Error Severity: ' + CONVERT(VARCHAR, ERROR_SEVERITY());
    END CATCH;
END;
GO

-- Debugging example
EXECUTE dbo.usp_DebugExample 10;

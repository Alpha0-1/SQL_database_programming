/*
  Filename: 5-procedure_exceptions.sql
  Description: Demonstrate exception handling using TRY...CATCH blocks.
  
  Parameters:
    None
  
  Example Usage:
    EXECUTE dbo.usp_ExceptionHandlingExample;
*/

USE YourDatabase;
GO

IF OBJECT_ID('dbo.usp_ExceptionHandlingExample', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_ExceptionHandlingExample;
GO

CREATE PROCEDURE dbo.usp_ExceptionHandlingExample
AS
BEGIN
    -- Set up error handling
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Example of a division by zero error
        DECLARE @Result INT;
        SET @Result = 10 / 0; -- This will cause an error
        
        PRINT 'Result: ' + CONVERT(VARCHAR, @Result);
        
    END TRY
    BEGIN CATCH
        -- Print error details
        PRINT 'Error Number: ' + CONVERT(VARCHAR, ERROR_NUMBER());
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        PRINT 'Error Line: ' + CONVERT(VARCHAR, ERROR_LINE());
    END CATCH;
END;
GO

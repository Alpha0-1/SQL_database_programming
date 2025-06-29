/*
  Filename: 1-procedure_parameters.sql
  Description: Demonstrate the use of input/output parameters in a stored procedure.
  
  Parameters:
    @InputParam INT   - Input parameter to be used within the procedure.
    @OutputParam INT OUTPUT - Output parameter that returns a value.

  Example Usage:
    DECLARE @Result INT;
    EXECUTE dbo.usp_ParametersExample 5, @Result OUTPUT;
    SELECT @Result AS OutputValue;
*/

USE YourDatabase;
GO

IF OBJECT_ID('dbo.usp_ParametersExample', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_ParametersExample;
GO

CREATE PROCEDURE dbo.usp_ParametersExample
    @InputParam INT,
    @OutputParam INT OUTPUT
AS
BEGIN
    -- Set up error handling
    SET NOCOUNT ON;
    
    -- Example logic using the input parameter
    DECLARE @Message VARCHAR(100);
    SET @Message = 'Input value: ' + CONVERT(VARCHAR, @InputParam);
    
    -- Print the message (for demonstration)
    PRINT @Message;
    
    -- Assign a value to the output parameter
    SET @OutputParam = @InputParam * 2;
END;
GO

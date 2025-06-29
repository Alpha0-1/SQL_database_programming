/*
  Filename: 4-procedure_cursors.sql
  Description: Demonstrate the use of cursors in a stored procedure.
  
  Parameters:
    None
  
  Example Usage:
    EXECUTE dbo.usp_CursorExample;
*/

USE YourDatabase;
GO

IF OBJECT_ID('dbo.usp_CursorExample', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_CursorExample;
GO

CREATE PROCEDURE dbo.usp_CursorExample
AS
BEGIN
    -- Set up error handling
    SET NOCOUNT ON;
    
    -- Declare cursor
    DECLARE @EmployeeID INT,
            @EmployeeName VARCHAR(100);
            
    -- Sample data table
    DECLARE @Employees TABLE (
        ID INT,
        Name VARCHAR(100)
    );
    
    -- Insert sample data
    INSERT INTO @Employees VALUES (1, 'John Doe');
    INSERT INTO @Employees VALUES (2, 'Jane Smith');
    INSERT INTO @Employees VALUES (3, 'Mike Johnson');
    
    -- Declare cursor for the sample data
    DECLARE EmployeeCursor CURSOR FOR
        SELECT ID, Name FROM @Employees;
    
    -- Open cursor
    OPEN EmployeeCursor;
    
    -- Fetch and process each row
    FETCH NEXT FROM EmployeeCursor INTO @EmployeeID, @EmployeeName;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT 'Employee ID: ' + CONVERT(VARCHAR, @EmployeeID);
        PRINT 'Employee Name: ' + @EmployeeName;
        PRINT '--------------------------------';
        
        FETCH NEXT FROM EmployeeCursor INTO @EmployeeID, @EmployeeName;
    END;
    
    -- Close and deallocate cursor
    CLOSE EmployeeCursor;
    DEALLOCATE EmployeeCursor;
END;
GO

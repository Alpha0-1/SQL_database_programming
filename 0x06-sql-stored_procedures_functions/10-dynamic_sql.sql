/*
  Filename: 10-dynamic_sql.sql
  Description: Demonstrate the execution of dynamic SQL within stored procedures.
  
  Stored Procedure Name: dbo.usp_ExecuteDynamicSQL
  Purpose: This procedure dynamically constructs and executes a SQL query based on input parameters.

  Parameters:
    @QueryType VARCHAR(20) - Specifies the type of query to execute ('SELECT' or 'UPDATE').
    @TableName VARCHAR(100) - The name of the table to execute the query on.
    @ColumnList VARCHAR(MAX) - Comma-separated list of columns to select or update.
    @WhereCondition VARCHAR(MAX) = NULL - Optional WHERE clause to filter the results.

  Example Usage:
    -- Execute a SELECT query
    EXECUTE dbo.usp_ExecuteDynamicSQL 'SELECT', 'Production.Product', 'ProductID, Name, ListPrice', 'WHERE ListPrice > 1000';
    
    -- Execute an UPDATE query
    EXECUTE dbo.usp_ExecuteDynamicSQL 'UPDATE', 'Production.Product', 'ListPrice = ListPrice * 1.10', 'WHERE CategoryID = 1';
*/

USE AdventureWorks;
GO

-- Drop the procedure if it exists
IF OBJECT_ID('dbo.usp_ExecuteDynamicSQL', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_ExecuteDynamicSQL;
GO

-- Create the stored procedure
CREATE PROCEDURE dbo.usp_ExecuteDynamicSQL
(
    @QueryType VARCHAR(20),
    @TableName VARCHAR(100),
    @ColumnList VARCHAR(MAX),
    @WhereCondition VARCHAR(MAX) = NULL
)
AS
BEGIN
    -- Build the dynamic SQL query
    DECLARE @DynamicSQL NVARCHAR(MAX);
    
    -- Construct SELECT query
    IF @QueryType = 'SELECT'
    BEGIN
        SET @DynamicSQL = N'SELECT ' + @ColumnList + N' FROM ' + @TableName;
        IF @WhereCondition IS NOT NULL
            SET @DynamicSQL = @DynamicSQL + N' ' + @WhereCondition;
    END
    -- Construct UPDATE query
    ELSE IF @QueryType = 'UPDATE'
    BEGIN
        SET @DynamicSQL = N'UPDATE ' + @TableName + N' SET ' + @ColumnList;
        IF @WhereCondition IS NOT NULL
            SET @DynamicSQL = @DynamicSQL + N' ' + @WhereCondition;
    END
    ELSE
    BEGIN
        RAISERROR('Invalid QueryType. Must be either SELECT or UPDATE.', 16, 1);
        RETURN;
    END;

    -- Execute the dynamic SQL statement
    EXECUTE sp_executesql @DynamicSQL;
END;
GO

-- Example usage
-- Execute a SELECT query
EXECUTE dbo.usp_ExecuteDynamicSQL 'SELECT', 'Production.Product', 'ProductID, Name, ListPrice', 'WHERE ListPrice > 1000';

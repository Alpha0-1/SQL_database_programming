/*
  Filename: 100-advanced_procedures.sql
  Description: Demonstrate advanced concepts in stored procedures.
  
  Stored Procedure Name:dbo.usp_AdvancedFeatures
  Purpose: This procedure showcases advanced features such as temporary tables, CTEs, and advanced control flow.

  Parameters:
    @Threshold INT - A threshold value for filtering data.

  Returns:
    A result set containing advanced data processing results.

  Example Usage:
    -- Execute with threshold value
    EXECUTE dbo.usp_AdvancedFeatures 100;
*/

USE AdventureWorks;
GO

-- Drop the procedure if it exists
IF OBJECT_ID('dbo.usp_AdvancedFeatures', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_AdvancedFeatures;
GO

-- Create the stored procedure with advanced features
CREATE PROCEDURE dbo.usp_AdvancedFeatures
(
    @Threshold INT
)
AS
BEGIN
    -- Create a temporary table
    CREATE TABLE #TempResults
    (
        ProductID INT,
        SalesAmount DECIMAL(18, 2),
        SalesQuantity INT
    );

    -- Populate the temporary table using a CTE
    WITH SalesCTE AS
    (
        SELECT 
            p.ProductID,
            SUM(od.OrderQuantity * od.UnitPrice) AS TotalSales,
            SUM(od.OrderQuantity) AS TotalQuantity
        FROM 
            Sales.SalesOrderDetail od
        JOIN 
            Production.Product p ON od.ProductID = p.ProductID
        GROUP BY
            p.ProductID
    )
    INSERT INTO #TempResults
    SELECT 
        ProductID,
        TotalSales,
        TotalQuantity
    FROM 
        SalesCTE
    WHERE 
        TotalSales > @Threshold;

    -- Advanced control flow
    DECLARE @RowCount INT;
    SELECT @RowCount = COUNT(*) FROM #TempResults;

    IF @RowCount > 0
    BEGIN
        PRINT 'Processing ' + CONVERT(VARCHAR, @RowCount) + ' records.';
        
        -- Process each record
        DECLARE @ProductID INT,
                @SalesAmount DECIMAL(18, 2),
                @SalesQuantity INT;
                
        DECLARE SalesCursor CURSOR FOR
            SELECT ProductID, SalesAmount, SalesQuantity FROM #TempResults;
            
        OPEN SalesCursor;
        FETCH NEXT FROM SalesCursor INTO @ProductID, @SalesAmount, @SalesQuantity;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Example processing logic
            UPDATE Production.Product
            SET ListPrice = ListPrice * 1.05
            WHERE ProductID = @ProductID;
            
            FETCH NEXT FROM SalesCursor INTO @ProductID, @SalesAmount, @SalesQuantity;
        END;
        CLOSE SalesCursor;
        DEALLOCATE SalesCursor;
    END
    ELSE
    BEGIN
        PRINT 'No records meet the threshold criteria.';
    END;

    -- Clean up
    DROP TABLE #TempResults;
END;
GO

-- Execute with threshold value
EXECUTE dbo.usp_AdvancedFeatures 100;

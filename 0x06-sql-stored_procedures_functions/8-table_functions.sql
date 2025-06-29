/*
  Filename: 8-table_functions.sql
  Description: Demonstrate the creation and usage of table-valued functions.
  
  Table-Valued Function Name: dbo.ufn_GetProductSalesByCategory
  Purpose: This function retrieves product sales data for a specified sales year.

  Parameters:
    @SalesYear SMALLINT - The year for which sales data is requested.

  Returns:
    A table with product sales data including ProductID, ProductName, CategoryName, and SalesAmount.

  Example Usage:
    SELECT * FROM dbo.ufn_GetProductSalesByCategory(2023);
*/

USE AdventureWorks;
GO

-- Drop the function if it exists
IF OBJECT_ID('dbo.ufn_GetProductSalesByCategory', 'FN') IS NOT NULL
    DROP FUNCTION dbo.ufn_GetProductSalesByCategory;
GO

-- Create the table-valued function
CREATE FUNCTION dbo.ufn_GetProductSalesByCategory
(
    @SalesYear SMALLINT
)
RETURNS TABLE
AS
RETURN
(
    -- SELECT statement to retrieve product sales data
    SELECT 
        p.ProductID,
        p.Name AS ProductName,
        pc.Name AS CategoryName,
        SUM(sod.OrderQuantity * sod.UnitPrice) AS SalesAmount
    FROM 
        Sales.SalesOrderDetail AS sod
    JOIN 
        Production.Product AS p ON sod.ProductID = p.ProductID
    JOIN 
        Production.ProductCategory AS pc ON p.ProductCategoryID = pc.ProductCategoryID
    JOIN 
        Sales.SalesOrderHeader AS soh ON sod.SalesOrderID = soh.SalesOrderID
    WHERE 
        DATEPART(YEAR, soh.OrderDate) = @SalesYear
    GROUP BY 
        p.ProductID, p.Name, pc.Name
    ORDER BY 
        SalesAmount DESC
);
GO

-- Example usage
SELECT * FROM dbo.ufn_GetProductSalesByCategory(2023);

/*
  Filename: 101-procedure_optimization.sql
  Description: Demonstrate optimization techniques for stored procedures.
  
  Stored Procedure Name: dbo.usp_OptimizedSalesReport
  Purpose: This procedure retrieves optimized sales reports with best practices in performance.

  Parameters:
    @ReportType VARCHAR(20) - Type of report to generate ('DAILY', 'WEEKLY', 'MONTHLY').

  Returns:
    A result set containing optimized sales data.

  Example Usage:
    -- Execute optimized sales report for monthly data
    EXECUTE dbo.usp_OptimizedSalesReport 'MONTHLY';
*/

USE AdventureWorks;
GO

-- Drop the procedure if it exists
IF OBJECT_ID('dbo.usp_OptimizedSalesReport', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_OptimizedSalesReport;
GO

-- Create the optimized stored procedure
CREATE PROCEDURE dbo.usp_OptimizedSalesReport
(
    @ReportType VARCHAR(20)
)
AS
BEGIN
    -- Enable high-performance options
    SET NOCOUNT ON;
    SET ANSI_WARNINGS OFF;
    
    -- Use parameter sniffing with local variables
    DECLARE @LocalReportType VARCHAR(20) = @ReportType;
    
    -- Optimize with proper indexing and join orders
    SELECT 
        soh.OrderDate,
        p.Name AS ProductName,
        od.OrderQuantity * od.UnitPrice AS SalesAmount
    FROM 
        Sales.SalesOrderHeader soh
    JOIN 
        Sales.SalesOrderDetail od ON soh.SalesOrderID = od.SalesOrderID
    JOIN 
        Production.Product p ON od.ProductID = p.ProductID
    WHERE 
        CASE 
            WHEN @LocalReportType = 'DAILY' THEN DATEADD(DAY, DATEDIFF(DAY, 0, soh.OrderDate), 0) = GETDATE()
            WHEN @LocalReportType = 'WEEKLY' THEN DATEADD(WEEK, DATEDIFF(WEEK, 0, soh.OrderDate), 0) = DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()), 0)
            WHEN @LocalReportType = 'MONTHLY' THEN DATEADD(MONTH, DATEDIFF(MONTH, 0, soh.OrderDate), 0) = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0)
            ELSE soh.OrderDate = GETDATE()
        END
    ORDER BY 
        soh.OrderDate DESC;
END;
GO

-- Optimize with proper indexes
EXECUTE sp_create_index 'Sales.SalesOrderHeader' , 'OrderDate';
EXECUTE sp_create_index 'Sales.SalesOrderDetail', 'SalesOrderID';
EXECUTE sp_create_index 'Production.Product', 'ProductID';

-- Execute optimized sales report
EXECUTE dbo.usp_OptimizedSalesReport 'MONTHLY';

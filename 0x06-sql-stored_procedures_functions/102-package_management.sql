/*
  Filename: 102-package_management.sql
  Description: Demonstrate package management for stored procedures and functions.
  
  Package Name: dbo.pkg_HumanResources
  Purpose: This package contains procedures and functions related to Human Resources operations.

  procedures included:
    - dbo.usp_EmployeeBenefits
    - dbo.usp_EmployeeTermination

  Functions included:
    - dbo.ufn_CalculateBonus
    - dbo.ufn_GetEmployeeBenefitsSummary

  Example Usage:
    -- Execute a procedure from the package
    EXECUTE dbo.usp_EmployeeBenefits 1;
    
    -- Use a function from the package
    SELECT dbo.ufn_CalculateBonus(50000) AS BonusAmount;
*/

USE AdventureWorks;
GO

-- Drop existing package components if they exist
IF OBJECT_ID('dbo.usp_EmployeeBenefits', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_EmployeeBenefits;
IF OBJECT_ID('dbo.usp_EmployeeTermination', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_EmployeeTermination;
IF OBJECT_ID('dbo.ufn_CalculateBonus', 'FN') IS NOT NULL
    DROP FUNCTION dbo.ufn_CalculateBonus;
IF OBJECT_ID('dbo.ufn_GetEmployeeBenefitsSummary', 'FN') IS NOT NULL
    DROP FUNCTION dbo.ufn_GetEmployeeBenefitsSummary;
GO

-- Create package procedures
CREATE PROCEDURE dbo.usp_EmployeeBenefits
(
    @EmployeeID INT
)
AS
BEGIN
    SELECT 
        e.EmployeeID,
        e.FirstName,
        e.LastName,
        b.BenefitType,
        b.Amount
    FROM 
        HumanResources.Employee e
    JOIN 
        HumanResources.EmployeeBenefits b ON e.EmployeeID = b.EmployeeID
    WHERE 
        e.EmployeeID = @EmployeeID;
END;
GO

CREATE PROCEDURE dbo.usp_EmployeeTermination
(
    @EmployeeID INT,
    @TerminationDate DATE
)
AS
BEGIN
    UPDATE HumanResources.Employee
    SET TerminationDate = @TerminationDate
    WHERE EmployeeID = @EmployeeID;
END;
GO

-- Create package functions
CREATE FUNCTION dbo.ufn_CalculateBonus
(
    @BaseSalary DECIMAL(18, 2)
)
RETURNS DECIMAL(18, 2)
AS
BEGIN
    RETURN @BaseSalary * 0.10; -- 10% bonus
END;
GO

CREATE FUNCTION dbo.ufn_GetEmployeeBenefitsSummary
(
    @EmployeeID INT
)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        b.BenefitType,
        SUM(b.Amount) AS TotalBenefits
    FROM 
        HumanResources.EmployeeBenefits b
    WHERE 
        b.EmployeeID = @EmployeeID
    GROUP BY 
        b.BenefitType;
);
GO

-- Example usage
-- Execute a procedure
EXECUTE dbo.usp_EmployeeBenefits 1;

-- Use a function
SELECT dbo.ufn_CalculateBonus(50000) AS BonusAmount;

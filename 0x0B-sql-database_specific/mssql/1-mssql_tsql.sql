/*
  Filename: 1-mssql_tsql.sql
  Description: Introduction to T-SQL scripting in SQL Server
  Author: Alpha0-1
*/

-- Step 1: Create a database
CREATE DATABASE TSQLExamples;
GO

USE TSQLExamples;

-- Step 2: Create a table
CREATE TABLE Employees (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    FirstName NVARCHAR(50),
    LastName NVARCHAR(50),
    Salary DECIMAL(10, 2)
);

-- Step 3: Insert sample data
INSERT INTO Employees VALUES
('John', 'Doe', 50000.00),
('Jane', 'Smith', 65000.00);

-- Step 4: Basic T-SQL SELECT
SELECTFirstName, LastName, Salary
FROM Employees;

-- Step 5: T-SQL Variables
DECLARE @TotalSalary DECIMAL(10, 2);
SET @TotalSalary = (SELECT SUM(Salary) FROM Employees);

SELECT @TotalSalary AS TotalSalary;

-- Step 6: Control Flow
IF (SELECT COUNT(*) FROM Employees) > 0
    PRINT 'There are employees in the table.';
ELSE
    PRINT 'The table is empty.';

/*
  Exercise:
  1. Create a stored procedure to insert new employees
  2. Practice using WHILE loops
  3. Implement a basic cursor for iteration
*/

-- Cleanup
--USE master;
--DROP DATABASE TSQLExamples;

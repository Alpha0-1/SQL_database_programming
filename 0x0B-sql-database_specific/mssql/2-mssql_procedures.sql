/*
  Filename: 2-mssql_procedures.sql
  Description: Creating and using stored procedures in SQL Server
  Author: Alpha0-1
*/

-- Step 1: Create a database
CREATE DATABASE ProceduresDB;
GO

USE ProceduresDB;

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

-- Step 4: Create a stored procedure to retrieve employees
CREATE PROCEDURE GetEmployees
AS
BEGIN
    SELECT Id, FirstName, LastName, Salary
    FROM Employees;
END;
GO

-- Step 5: Execute the stored procedure
EXEC GetEmployees;

-- Step 6: Create a parameterized stored procedure
CREATE PROCEDURE GetEmployeeById
    @EmployeeId INT
AS
BEGIN
    SELECT Id, FirstName, LastName, Salary
    FROM Employees
    WHERE Id = @EmployeeId;
END;
GO

-- Step 7: Execute the parameterized procedure
EXEC GetEmployeeById @EmployeeId = 1;

-- Step 8: Create a procedure to add an employee
CREATE PROCEDURE AddEmployee
    @FirstName NVARCHAR(50),
    @LastName NVARCHAR(50),
    @Salary DECIMAL(10, 2)
AS
BEGIN
    INSERT INTO Employees (FirstName, LastName, Salary)
    VALUES (@FirstName, @LastName, @Salary);
END;
GO

-- Step 9: Execute the add employee procedure
EXEC AddEmployee 'Bob', 'Johnson', 55000.00;

/*
  Exercise:
  1. Create a stored procedure to update employee salary
  2. Implement input validation in procedures
  3. Practice using transactions within procedures
*/

-- Cleanup
--USE master;
--DROP DATABASE ProceduresDB;

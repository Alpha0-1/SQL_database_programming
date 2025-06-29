/*
  Filename: 0-mssql_basics.sql
  Description: Basic SQL Server operations
  Author: Alpha0-1
*/

-- Step 1: Create a new database
CREATE DATABASE BasicDB;
GO

USE BasicDB;

-- Step 2: Create a table with identity column
CREATE TABLE Employees (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Salary DECIMAL(10, 2) DEFAULT 0,
    HireDate DATE,
    Department NVARCHAR(50)
);

-- Step 3: Insert data
INSERT INTO Employees (FirstName, LastName, Salary, HireDate, Department)
VALUES
('John', 'Doe', 50000.00, '2023-01-15', 'HR'),
('Jane', 'Smith', 65000.00, '2023-03-20', 'Engineering'),
('Bob', 'Johnson', 55000.00, '2023-05-10', 'Marketing');

-- Step 4: Basic SELECT query
SELECT * FROM Employees;

-- Step 5: Filter and sort
SELECT FirstName, LastName, Salary 
FROM Employees 
WHERE Department = 'Engineering'
ORDER BY HireDate DESC;

/*
  Exercise:
  1. Add a ' PhoneNumber' column with data type NVARCHAR(15)
  2. Write a query to get employees with salary > 50000
  3. Practice using TOP to get top 2 employees
*/

-- Cleanup
--USE master;
--DROP DATABASE BasicDB;

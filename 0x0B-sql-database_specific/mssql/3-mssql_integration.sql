/*
  Filename: 3-mssql_integration.sql
  Description: SQL Server integration with other systems
  Author: Alpha0-1
*/

-- Step 1: Create a database
CREATE DATABASE IntegrationDB;
GO

USE IntegrationDB;

-- Step 2: Create a table to hold data from a linked server
CREATE TABLE LinkedData (
    id INT,
    name NVARCHAR(50),
    value DECIMAL(10, 2)
);

-- Step 3: Create a linked server
EXEC sp_addlinkedserver 
    @server = 'LinkedOracle', 
    @provider = 'OraOLEDB.Oracle', 
    @datasrc = 'OracleServer';

-- Step 4: Query data from the linked server
SELECT * 
FROM OPENQUERY(LinkOracle, 'SELECT employee_id, first_name FROM employees');

-- Step 5: Create a stored procedure to pull data from the linked server
CREATE PROCEDURE PullLinkedData AS
BEGIN
    INSERT INTO LinkedData (id, name, value)
    SELECT employee_id, first_name, salary 
    FROM LinkOracle...employees;
END;
GO

-- Step 6: Execute the stored procedure
EXEC PullLinkedData;

-- Step 7: Clean up linked server
EXEC sp_dropserver 'LinkedOracle', 'droplogins';

/*
  Exercise:
  1. Configure a linked server to another database system
  2. Implement a stored procedure to synchronize data between databases
  3. Practice using distributed transactions
*/

-- Cleanup
--USE master;
--DROP DATABASE IntegrationDB;

/*
  Filename: 100-mssql_advanced.sql
  Description: Advanced SQL Server features and techniques
  Author: Alpha0-1
*/

-- Step 1: Create a database
CREATE DATABASE AdvancedDB;
GO

USE AdvancedDB;

-- Step 2: Create a table with advanced data types
CREATE TABLE_AdvancedTypes (
    id INT IDENTITY PRIMARY KEY,
    data XML,
    image VARBINARY(MAX)
);

-- Step 3: Insert XML data
INSERT INTO AdvancedTypes (data)
VALUES
('<employee>
    <name>John Doe</name>
    <department>HR</department>
    <salary>50000</salary>
</employee>');

-- Step 4: Query XML data
SELECT data.value('(employee/name)[1]', 'VARCHAR(50)') AS employee_name
FROM AdvancedTypes;

-- Step 5: Create a table with FILESTREAM
CREATE TABLE FileStorage (
    id INT PRIMARY KEY,
    file_data VARBINARY(MAX) FILESTREAM
);

-- Step 6: Enable FILESTREAM support
-- Configuration required on SQL Server settings

-- Step 7: Insert BLOB data
INSERT INTO FileStorage (id, file_data)
SELECT 1, BulkColumn FROM OPENROWSET(
    BULK 'C:\path\to\image.jpg',
    SINGLE_BLOB
) AS b;

-- Step 8: Retrieve BLOB data
SELECT TOP 1 * FROM FileStorage;

-- Step 9: Use advanced indexing
CREATE INDEX idx_Data ON AdvancedTypes (data.value('(employee/name)[1]', 'VARCHAR(50)'));

/*
  Exercise:
  1. Implement full-text search on a text column
  2. Practice using spatial data types
  3. Explore SQLCLR integration (if enabled)
*/

-- Cleanup
--USE master;
--DROP DATABASE AdvancedDB;

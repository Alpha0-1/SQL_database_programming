/*
** Topic: User Creation and Management
** Description: Examples of creating, altering, and managing SQL users.
** Learning Objectives:
**   1. Understand how to create new database users
**   2. Learn how to modify existing user permissions
**   3. Explore user authentication methods
*/

-- Creating a new database user with SQL Server authentication
CREATE LOGIN db_user1 WITH PASSWORD = 'StrongP@ssw0rd123!', 
DEFAULT_DATABASE = master,
CHECK_POLICY = ON;

-- Creating a user in specific database
USE AdventureWorks;
GO
CREATE USER db_user1 FOR LOGIN db_user1
WITH DEFAULT_SCHEMA = HumanResources;

-- Altering user permissions
ALTER USER db_user1 WITH DEFAULT_SCHEMA = Production;

-- Granting permissions
GRANT SELECT, INSERT ON Production.Product TO db_user1;

-- Revoking permissions
REVOKE INSERT ON Production.Product FROM db_user1;

-- Dropping a user (Caution: Be careful with DROP operations)
DROP USER db_user1;
DROP LOGIN db_user1;

-- Best practices:
-- Use complex passwords and never reuse them
-- Limit permissions to the minimum required (Principle of Least Privilege)
-- Regularly audit user permissions

/*
** Topic: Role-Based Access Control (RBAC)
** Description: Examples of creating, modifying, and managing database roles.
** Learning Objectives:
**   1. Understand how to implement RBAC
**   2. Learn to create custom roles
**   3. Understand role hierarchy and permissions
*/

-- Create a custom database role
USE AdventureWorks;
GO
CREATE ROLE SalesManager;

-- Add permissions to the role
GRANT SELECT, INSERT, UPDATE, DELETE ON Sales.SalesOrderHeader TO SalesManager;

-- Add a user to the role
EXEC sp_addrolemember 'SalesManager', 'db_user1';

-- Modify role permissions
GRANT EXECUTE ON Sales.ufnGetProductListPrice TO SalesManager;

-- Remove a user from a role
EXEC sp_droprolemember 'SalesManager', 'db_user1';

-- Drop a role (Use with caution)
DROP ROLE SalesManager;

-- Best practices:
-- Use predefined roles where possible
-- Avoid over-permissive roles
-- Regularly audit role membership and permissions

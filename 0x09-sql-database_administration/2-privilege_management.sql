/*
** Topic: Privilege Assignment
** Description: Examples of assigning and managing database privileges.
** Learning Objectives:
**   1. Understand SQL privilege levels
**   2. Learn to assign privileges to users and roles
**   3. Explore privilege auditing
*/

-- Example: Assigning privileges to a user
GRANT EXECUTE ON AdventureWorks.dbo.ufnGetProductListPrice TO db_user1;

-- Example: Revoking privileges
REVOKE EXECUTE ON AdventureWorks.dbo.ufnGetProductListPrice FROM db_user1;

-- Example: Granting privileges to a role
GRANT SELECT, INSERT ON Sales.SalesOrderDetail TO SalesManager;

-- Example: Deny privileges (Use carefully)
DENY DELETE ON Sales.SalesOrderDetail TO SalesManager;

-- Best practices:
-- Use DENY sparingly as it can override other permissions
-- Always test privilege changes in a non-production environment
-- Regularly audit privileges

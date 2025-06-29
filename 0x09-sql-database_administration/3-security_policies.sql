/*
** Topic: Security Policy Implementation
** Description: Examples of implementing database security policies.
** Learning Objectives:
**   1. Understand SQL security policies
**   2. Learn to enforce data security
**   3. Explore sensitive data protection
*/

-- Create a security policy for sensitive data
CREATE SECURITY POLICY Sales.SalesDataPolicy
ADD FILTER PREDICATE Sales.fnCheckSalesDataAccess(EmployeeID) 
ON AdventureWorks.Sales.SalesOrderHeader
WITH (STATE = ON);

-- Example predicate function
CREATE FUNCTION Sales.fnCheckSalesDataAccess(@EmployeeID INT)
RETURNS INT
AS
BEGIN
    IF (IS_MEMBER('SalesManager') = 1 OR @EmployeeID = SUSER_ID())
        RETURN 1;
    ELSE
        RETURN 0;
END;
GO

-- Enable security policy
ALTER SECURITY POLICY Sales.SalesDataPolicy 
STATE = ON;

-- Drop a security policy (Use with caution)
DROP SECURITY POLICY Sales.SalesDataPolicy;

-- Best practices:
-- Always test security policies in a development environment
-- Monitor security policy performance
-- Regularly audit security policies

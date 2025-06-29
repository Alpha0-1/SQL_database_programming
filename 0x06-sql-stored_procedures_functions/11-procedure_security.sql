/*
  Filename: 11-procedure_security.sql
  Description: Demonstrate security considerations within stored procedures.
  
  Stored Procedure Name: dbo.usp_SecureDataAccess
  Purpose: This procedure implements secure access to sensitive data, including row-level security.

  Parameters:
    @UserID INT - The ID of the user requesting data access.
    @DataCategory VARCHAR(50) - The category of data to access.

  Returns:
    A result set containing sensitive data filtered based on user permissions.

  Example Usage:
    -- Secure access based on user permissions
    EXECUTE dbo.usp_SecureDataAccess 1, 'FINANCIAL';
*/

USE AdventureWorks;
GO

-- Drop the procedure if it exists
IF OBJECT_ID('dbo.usp_SecureDataAccess', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_SecureDataAccess;
GO

-- Create the stored procedure with security considerations
CREATE PROCEDURE dbo.usp_SecureDataAccess
(
    @UserID INT,
    @DataCategory VARCHAR(50)
)
AS
BEGIN
    -- Secure access control
    DECLARE @HasAccess BIT;
    SELECT @HasAccess = CASE 
                         WHEN EXISTS (SELECT 1 
                                     FROM Security.UserPermissions 
                                     WHERE UserID = @UserID 
                                           AND DataCategory = @DataCategory) THEN 1
                         ELSE 0
                       END;

    -- Check access permission
    IF @HasAccess = 0
    BEGIN
        RAISERROR('User does not have access to this data category.', 16, 1);
        RETURN;
    END;

    -- Secure data access logic
    SELECT DataID, DataValue, AccessLevel
    FROM Security.SensitiveData
    WHERE DataCategory = @DataCategory 
          AND DataID IN (SELECT DataID 
                          FROM Security.UserAccess 
                          WHERE UserID = @UserID);
END;
GO

-- Secure data access example
EXECUTE dbo.usp_SecureDataAccess 1, 'FINANCIAL';

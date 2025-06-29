/*
** Topic: Storage Space Management
** Description: Examples of managing database files and space.
** Learning Objectives:
**   1. Manage file growth
**   2. Check disk space
**   3. Configure filegroups
*/

-- Check disk space usage
EXEC sp_helpdb AdventureWorks;

-- Resize a database file
ALTER DATABASE AdventureWorks
MODIFY FILE (NAME = AdventureWorks_Log, SIZE = 100MB);

-- Example of managing filegroups
CREATE FILEGROUP Data_FG1;
ALTER DATABASE AdventureWorks ADD FILE (
     NAME = Data1,
     FILENAME = 'C:\Data\Data1.ndf',
     SIZE = 100MB,
     FILEGROWTH = 10MB)
TO FILEGROUP Data_FG1;

-- Best practices:
-- Monitor disk space regularly
-- Set appropriate auto-growth settings
-- Use filegroups to organize data

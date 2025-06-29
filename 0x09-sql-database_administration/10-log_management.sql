/*
** Topic: Transaction Log Management
** Description: Examples of managing transaction logs.
** Learning Objectives:
**   1. Configure transaction log backups
**   2. Monitor log file growth
**   3. Shrink transaction logs
*/

-- Configure transaction log backups
BACKUP LOG AdventureWorks
TO DISK = 'C:\MSSQL\Backups\AdventureWorks_Log.trn'
WITH CHECKSUM, COMPRESSION;

-- Monitor transaction log space
DBCC SQLPERF('LogSpace', 1);

-- Shrink transaction log
DBCC SHRINKFILE (AdventureWorks_Log, 10);

-- Best practices:
-- Regularly back up transaction logs
-- Monitor log file size and growth
-- Avoid shrinking logs too frequently

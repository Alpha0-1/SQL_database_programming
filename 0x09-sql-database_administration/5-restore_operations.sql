/*
** Topic: Restore Operations
** Description: Examples of restoring databases from backups.
** Learning Objectives:
**   1. Understand full, differential, and transaction log restores
**   2. Learn to configure restore options
**   3. Explore restore best practices
*/

-- Full database restore
RESTORE DATABASE AdventureWorks 
FROM DISK = 'C:\MSSQL\Backups\AdventureWorks_Full.bak'
WITH REPLACE, RECOVERY;

-- Differential restore
RESTORE DATABASE AdventureWorks 
FROM DISK = 'C:\MSSQL\Backups\AdventureWorks_Diff.bak'
WITH FILE = 1, NORECOVERY;

-- Transaction log restore
RESTORE LOG AdventureWorks 
FROM DISK = 'C:\MSSQL\Backups\AdventureWorks_Log.trn'
WITH RECOVERY;

-- Restore with switching recovery models
ALTER DATABASE AdventureWorks SET RECOVERY SIMPLE;

-- Restore validation
RESTORE VERIFYONLY FROM DISK = 'C:\MSSQL\Backups\AdventureWorks_Full.bak';

-- Best practices:
-- Always verify backups before restoration
-- Maintain a recovery plan
-- Regularly test restore processes

/*
** Topic: Backup Strategies
** Description: Examples of implementing database backup strategies.
** Learning Objectives:
**   1. Understand full, differential, and transaction log backups
**   2. Learn to configure backup schedules
**   3. Explore backup validation
*/

-- Full database backup
BACKUP DATABASE AdventureWorks 
TO DISK = 'C:\MSSQL\Backups\AdventureWorks_Full.bak'
WITH INIT, CHECKSUM, COMPRESSION;

-- Differential database backup
BACKUP DATABASE AdventureWorks 
TO DISK = 'C:\MSSQL\Backups\AdventureWorks_Diff.bak'
WITH DIFFERENTIAL, CHECKSUM, COMPRESSION;

-- Transaction log backup
BACKUP LOG AdventureWorks 
TO DISK = 'C:\MSSQL\Backups\AdventureWorks_Log.trn'
WITH CHECKSUM, COMPRESSION;

-- Backup history monitoring
SELECT 
    backup_start_date,
    backup_finish_date,
    database_name,
    backup_type,
    server_name,
    destination_description
FROM msdb.dbo.backupset
WHERE database_name = 'AdventureWorks'
ORDER BY backup_start_date DESC;

-- Best practices:
-- Always test backups
-- Maintain multiple backup copies
-- Regularly review backup performance

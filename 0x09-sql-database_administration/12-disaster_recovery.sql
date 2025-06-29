/*
** Topic: Disaster Recovery Planning
** Description: Examples of implementing disaster recovery strategies.
** Learning Objectives:
**   1. Set up failover clusters
**   2. Configure database mirroring
**   3. Test recovery procedures
*/

-- Example of setting up database mirroring
EXEC sp_executesql N'
USE AdventureWorks;
ALTER DATABASE AdventureWorks SET PARTNER = ''TCP://MirrorServer:5022'''
,''';

EXEC sp_executesql N'
USE AdventureWorks;
ALTER DATABASE AdventureWorks SET WITNESS = ''TCP://WitnessServer:5023'''
,''';

-- Example of testing recovery
RESTORE DATABASE AdventureWorks 
FROM DISK = 'C:\MSSQL\Backups\AdventureWorks_Full.bak'
WITH REPLACE, RECOVERY;

-- Best practices:
-- Regularly test recovery plans
-- Maintain up-to-date backups
-- Document recovery procedures

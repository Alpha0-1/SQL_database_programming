/*
** Topic: Automation Scripts
** Description: Examples of automating database tasks.
** Learning Objectives:
**   1. Write automation scripts
**   2. Use SQL Agent jobs
**   3. Schedule automated tasks
*/

-- Example of creating a SQL Agent job
EXEC sp_add_job @job_name = 'NightlyBackup';
EXEC sp_add_jobstep @job_name = 'NightlyBackup', 
@step_name = 'BackupDatabase',
@subsystem = 'TSQL',
@command = ' BACKUP DATABASE AdventureWorks 
TO DISK = ''C:\MSSQL\Backups\AdventureWorks_Nightly.bak'' 
WITH INIT, CHECKSUM, COMPRESSION;'
EXEC sp_add_schedule @job_name = 'NightlyBackup', 
@schedule_name = 'NightlyAtMidnight',
@freq_type = 4,
@freq_interval = 1,
@freq_subday_type = 1,
@freq_subday_interval = 0,
@active_start_time = 000000;
EXEC sp_attach_schedule @job_name = 'NightlyBackup', 
@schedule_name = 'NightlyAtMidnight';

-- Example of using Powershell for automation
-- See accompanying documentation for Powershell examples

-- Best practices:
-- Test scripts thoroughly
-- Document automation processes
-- Regularly review and update scripts

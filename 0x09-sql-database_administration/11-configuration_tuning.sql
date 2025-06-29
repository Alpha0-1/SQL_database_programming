/*
** Topic: Database Configuration Tuning
** Description: Examples of tuning database configurations.
** Learning Objectives:
**   1. Configure database options
**   2. Adjust server settings
**   3. Optimize memory settings
*/

-- Configure database options
ALTER DATABASE AdventureWorks SET RECOVERY SIMPLE;

-- Adjust server settings
EXEC sp_configure 'show advanced options',1;
RECONFIGURE;
EXEC sp_configure 'max server memory (MB)', 4096;
RECONFIGURE;

-- Optimize memory settings
DBCC MEMORYSTATUS;

-- Best practices:
-- Test configuration changes in a development environment
-- Regularly review server settings
-- Use appropriate logging and monitoring tools

/*
** Topic: Database Maintenance
** Description: Examples of routine database maintenance tasks.
** Learning Objectives:
**   1. Understand index maintenance
**   2. Learn to update statistics
**   3. Explore maintenance tasks like shrinking files
*/

-- Rebuild indexes
ALTER INDEX ALL ON Production.Product REBUILD;

-- Update statistics
UPDATE STATISTICS Production.Product WITH FULLSCAN;

-- Example of a maintenance plan: Shrinking a database file
DBCC SHRINKFILE (AdventureWorks_Log, 10);

-- Best practices:
-- Schedule regular maintenance
-- Monitor database growth
-- Regularly review maintenance performance

/*
 * Filename: 102-backup_restore.sql
 * Description: Demonstrates backup and restore operations in SQL
 */

/*
 * Section 1: Backup and Restore Overview
 * This script shows how to create backups and restore data in SQL
 * It uses mysqldump for logical backups and standard SQL for restore operations
 */

/*
 * Section 2: Creating a Sample Database
 * First, we'll create a sample database and tables to demonstrate backup/restore
 */

-- Create a sample database
DROP DATABASE IF EXISTS backup_restore_demo;
CREATE DATABASE backup_restore_demo;
USE backup_restore_demo;

-- Create a sample table
DROP TABLE IF EXISTS employees;
CREATE TABLE employees (
    employee_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE,
    salary DECIMAL(10,2),
    hire_date DATE
);

-- Insert sample data
INSERT INTO employees (first_name, last_name, email, salary, hire_date)
VALUES
('John', 'Doe', 'john.doe@example.com', 50000.00, '2020-01-15'),
('Jane', 'Smith', 'jane.smith@example.com', 60000.00, '2019-03-22'),
('Mike', 'Johnson', 'mike.johnson@example.com', 75000.00, '2021-07-05');

/*
 * Section 3: Full Database Backup
 * This section demonstrates how to create a full backup of a database
 */

-- Full backup using mysqldump
-- Execute the following command in the terminal:
-- mysqldump -u your_username -p backup_restore_demo > full_backup.sql

-- Verified in SQL:
-- You can verify the backup file exists and contains SQL statements
-- Example: CHECKSUM TABLE employees;

/*
 * Section 4: Incremental Backup
 * This section demonstrates how to create incremental backups
 */

-- Backup changes since the last backup
-- Use the WHERE clause to filter data (e.g., last week's data)
-- Execute this command in the terminal:
-- mysqldump -u your_username -p backup_restore_demo --where "hire_date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)" > incremental_backup.sql

/*
 * Section 5: Partial Backup: Specific Tables or Schemas
 * This section shows how to back up specific tables or schemas
 */

-- Backup individual tables
-- mysqldump -u your_username -p backup_restore_demo employees > partial_backup.sql

/*
 * Section 6: Restore Operations
 * This section demonstrates how to restore data from backup files
 */

-- Section 6.1: Full Database Restore
-- To restore a full backup, follow these steps:
-- 1. Drop or create the target database
-- DROP DATABASE IF EXISTS restore_demo;
-- CREATE DATABASE restore_demo;

-- 2. Restore the backup
-- Execute this command in the terminal:
-- mysql -u your_username -p restore_demo < full_backup.sql

-- 3. Verify the restore
USE restore_demo;
SELECT * FROM employees;

/*
 * Section 6.2: Incremental Restore
 * Apply incremental backups to an existing database
 */

-- To restore incremental changes:
-- Execute this command in the terminal:
-- mysql -u your_username -p restore_demo < incremental_backup.sql

-- Verify incremental changes
SELECT * FROM employees WHERE hire_date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY);

/*
 * Section 6.3: Partial Restore
 * Restore specific tables from a backup
 */

-- Restore a specific table
-- Execute this command in the terminal:
-- mysql -u your_username -p restore_demo < partial_backup.sql

-- Verify the restored table
SELECT * FROM employees;

/*
 * Section 7: Snapshot Backup (if applicable)
 * Some DBMS support snapshots for point-in-time recovery
 * Here's an example for MySQL (requires Enterprise Edition or compatible tools):
 */

-- Note: This section is for reference only and may not work on all systems.
-- Take a snapshot backup using mysqlbackup or Percona XtraBackup
-- Execute this command in the terminal:
-- mysqlbackup --user=root --socket=/path/to/socket --backup-dir=/path/to/backup backup-and-apply-log

-- Restore from a snapshot
-- mysqlbackup --user=root --socket=/path/to/socket --backup-dir=/path/to/backup restore

/*
 * Section 8: Error Handling and Verification
 * Ensure backups are valid and restores are successful
 */

-- Verify backup integrity
CHECKSUM TABLE employees;

-- Verify database consistency
SHOW TABLE STATUS LIKE 'employees';

-- Check data integrity
SELECT COUNT(*) AS record_count,
       MIN(hire_date) AS first_hire_date,
       MAX(hire_date) AS last_hire_date,
       AVG(salary) AS average_salary
FROM employees;

/*
 * Section 9: Backup and Restore Automation
 * Automate backups using scheduled tasks
 */

-- Example cron job to create daily backups
-- Add this to your crontab:
# 0 0 * * * /usr/bin/mysqldump -u your_username -p your_password backup_restore_demo > /path/to/backup/full_backup_`date +\%Y\%m\%d`.sql

/*
 * Section 10: Cleanup
 * Optional: Clean up the sample database
 */

DROP DATABASE IF EXISTS backup_restore_demo;
DROP DATABASE IF EXISTS restore_demo;

/*
 * Section 11: Testing and Verification
 * Test your backup and restore process regularly
 */

-- Perform a test restore on a test database
-- 1. Create a test database
-- CREATE DATABASE test_restore;

-- 2. Restore from backup
-- mysql -u your_username -p test_restore < full_backup.sql

-- 3. Verify data
-- USE test_restore;
SELECT * FROM employees;

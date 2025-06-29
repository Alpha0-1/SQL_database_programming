/*
  Filename: 0-oracle_basics.sql
  Description: Introduction to Oracle SQL basics including database creation, table manipulation, and data insertion
  Author: Alpha0-1
*/

-- Step 1: Connect to the Oracle database as a sysdba or system user
-- Command to connect:
-- sqlplus sys/password as sysdba

-- Step 2: Create a new database (if necessary)
-- Note: This step typically requires DBCA (Database Configuration Assistant) and is beyond basic SQL scripting.

-- Step 3: Create a table
CREATE TABLE employees (
    employee_id NUMBER PRIMARY KEY,
    first_name VARCHAR2(50) NOT NULL,
    last_name VARCHAR2(50) NOT NULL,
    email VARCHAR2(100) UNIQUE,
    hire_date DATE DEFAULT SYSDATE,
    salary NUMBER(10, 2),
    department_id NUMBER
);

-- Explanation:
-- - VARCHAR2 is used for variable-length character strings up to 5

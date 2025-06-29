/*
  Filename: 100-postgresql_advanced.sql
  Description: Advanced PostgreSQL features including stored procedures, indexing, and extensions
  Author: Alpha0-1
*/

-- Step 1: Connect to the database
\c advanced_db;

-- Step 2: Create stored procedures and functions in PL/pgSQL
-- Stored procedure to add an employee
CREATE OR REPLACE PROCEDURE add_employee(
    p_first_name VARCHAR(50),
    p_last_name VARCHAR(50),
    p_salary DECIMAL(10, 2),
    p_department VARCHAR(50)
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO employees (first_name, last_name, salary, department)
    VALUES (p_first_name, p_last_name, p_salary, p_department);
    COMMIT;
END;
$$;

-- Function to calculate total sales for a department
CREATE OR REPLACE FUNCTION get_total_sales(p_department VARCHAR(50))
RETURNS DECIMAL(10, 2) AS
$$
DECLARE
    v_total DECIMAL(10, 2);
BEGIN
    SELECT SUM(salary) INTO v_total
    FROM employees
    WHERE department = p_department;
    RETURN v_total;
END;
$$ LANGUAGE plpgsql;

-- Step 3: Advanced indexing techniques
-- Create a partial index on departments with salary over 50,000
CREATE INDEX idx_high_salary ON employees (last_name)
WHERE salary > 50000;

-- Create an expression index for uppercase names
CREATE INDEX idx_upper_name ON employees ((UPPER(first_name)));

-- Step 4: External data integration using Foreign Data Wrappers
-- Install postgres_fdw extension
CREATE EXTENSION postgres_fdw;

-- Create a foreign server for remote access
CREATE SERVER remote_server
    FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (
        host 'remote.example.com',
        port '5432',
        dbname 'remote_db'
    );

-- Create user mapping for the foreign server
CREATE USER MAPPING FOR public
    SERVER remote_server
    OPTIONS (
        username 'remote_user',
        password 'securepassword'
    );

-- Create a foreign table to access remote data
CREATE FOREIGN TABLE remote_employees (
    id INT,
    name VARCHAR(50),
    salary DECIMAL(10, 2)
) SERVER remote_server
OPTIONS (
    schema_name 'public',
    table_name 'employees'
);

-- Step 5: Database partitioning
-- Partition the employees table by department
CREATE TABLE employees_partition
(
CREATE TABLE employees (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    salary DECIMAL(10, 2),
    department VARCHAR(50)
) PARTITION BY LIST (department);

-- Create child partitions
CREATE TABLE employees_sales PARTITION OF employees
FOR VALUES IN ('Sales');

CREATE TABLE employees_engineering PARTITION OF employees
FOR VALUES IN ('Engineering');

-- Step 6: Advanced queries and transactions
-- Using Common Table Expressions (CTEs)
WITH dept_summary AS (
    SELECT department, SUM(salary) AS total_salary
    FROM employees
    GROUP BY department
)
SELECT department, total_salary, (total_salary / (SELECT SUM(total_salary) FROM dept_summary)) * 100 AS percentage
FROM dept_summary;

-- Transaction with isolation level
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;

-- Perform operations
COMMIT;

-- Step 7: PostgreSQL extensions
-- Install and use postgis extension for geospatial data
CREATE EXTENSION postgis;

-- Create a table with a geometry column
CREATE TABLE locations (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50),
    geom GEOMETRY
);

-- Insert geospatial data
INSERT INTO locations (name, geom)
VALUES
('HQ', ST_GeomFromText('POINT(-74.0060 40.7128)', 4326)),
('Office', ST_GeomFromText('POINT(-74.0059 40.7129)', 4326));

-- Query spatial data
SELECT name, ST_AsText(geom) AS coordinates
FROM locations;

-- Step 8: Error handling and logging
-- Example function with exception handling
CREATE OR REPLACE FUNCTION safe_division(numerator INT, denominator INT)
RETURNS DECIMAL(10, 2) AS
$$
DECLARE
    result DECIMAL(10, 2);
BEGIN
    IF denominator = 0 THEN
        RAISE EXCEPTION 'Division by zero attempted';
    END IF;
    result = numerator / denominator;
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Capture and log errors
DO
$$
DECLARE
    result DECIMAL(10, 2);
BEGIN
    BEGIN
        result = safe_division(10, 0);
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Error occurred: %', SQLERRM;
    END;
END;
$$;

-- Step 9: Security and roles
-- Create a new role with specific privileges
CREATE ROLE readonly_user LOGIN
    NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION
    PASSWORD 'readonlypass';

-- Grant select privileges on a table
GRANT SELECT ON employees TO readonly_user;

/*
  Exercise:
  1. Create a stored procedure to update employee salaries
  2. Implement a composite index and observe performance changes
  3. Use FDW to integrate with a remote database
  4. Partition an existing large table and analyze performance improvements
  5. Explore more PostgreSQL extensions and implement one in your use case
  6. Practice writing functions with error handling for various scenarios
*/

-- Cleanup
-- Drop procedures, functions, and extensions
-- DROP PROCEDURE add_employee(VARCHAR, VARCHAR, DECIMAL, VARCHAR);
-- DROP FUNCTION get_total_sales(VARCHAR);
-- DROP INDEX idx_high_salary, idx_upper_name;
-- DROP EXTENSION postgis;
-- DROP TABLE employees, locations, remote_employees;
-- DROP SERVER remote_server;
-- DROP ROLE readonly_user;
-- DROP USER MAPPING FOR public SERVER remote_server;
\q

-- MySQL Basics: Creating a Database and Table

-- Create a new database if it doesn't exist
CREATE DATABASE IF NOT EXISTS company_db;

-- Use the newly created database
USE company_db;

-- Create a table for employees
CREATE TABLE IF NOT EXISTS employees (
    id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    hire_date DATE
);

-- Insert sample data into the employees table
INSERT INTO employees (first_name, last_name, email, hire_date)
VALUES
    ('John', 'Doe', 'john.doe@example.com', '2023-01-15'),
    ('Jane', 'Smith', 'jane.smith@example.com', '2022-11-20');

-- Query all records from the employees table
SELECT * FROM employees;

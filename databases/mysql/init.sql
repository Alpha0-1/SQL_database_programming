-- MySQL Initialization Script

-- Create a sample database and table
CREATE DATABASE IF NOT EXISTS school_db;

USE school_db;

-- Create a students table
CREATE TABLE IF NOT EXISTS students (
    student_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    date_of_birth DATE
);

-- Insert sample data
INSERT INTO students (first_name, last_name, email, date_of_birth)
VALUES
    ('Alice', 'Johnson', 'alice@example.com', '2000-03-15'),
    ('Bob', 'Smith', 'bob@example.com', '1999-07-22');

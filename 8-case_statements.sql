-- 8-case_statements.sql
-- Purpose: Demonstrate complex CASE statements
-- Author: Alpha0-1

-- Table of student grades
CREATE TABLE IF NOT EXISTS grades (
    student_name VARCHAR(100),
    score INT
);

-- Insert sample data
INSERT INTO grades (student_name, score) VALUES
('Alice', 95),
('Bob', 82),
('Charlie', 75),
('Diana', 60),
('Eve', 55);

-- Use CASE to categorize scores into letter grades
SELECT
    student_name,
    score,
    CASE
        WHEN score >= 90 THEN 'A'
        WHEN score >= 80 THEN 'B'
        WHEN score >= 70 THEN 'C'
        WHEN score >= 60 THEN 'D'
        ELSE 'F'
    END AS grade
FROM grades;

-- Use CASE in an aggregate function
SELECT
    COUNT(*) FILTER (WHERE score >= 90) AS num_a,
    COUNT(*) FILTER (WHERE score BETWEEN 80 AND 89) AS num_b
FROM grades;

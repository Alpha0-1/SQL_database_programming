-- 3-third_normal_form.sql: Demonstration of Third Normal Form (3NF)

-- 3NF eliminates transitive dependencies. All non-key fields must depend only on the primary key.

-- Violation of 3NF
CREATE TABLE IF NOT EXISTS employees_violates_3nf (
    employee_id INT PRIMARY KEY,
    department_id INT,
    department_head TEXT -- Transitive dependency
);

-- Fix by removing transitive dependency
CREATE TABLE IF NOT EXISTS departments (
    department_id SERIAL PRIMARY KEY,
    department_head TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS employees (
    employee_id SERIAL PRIMARY KEY,
    department_id INT REFERENCES departments(department_id)
);

-- Insert sample data
INSERT INTO departments (department_head) VALUES ('Dr. Smith'), ('Prof. Lee');
INSERT INTO employees (department_id) VALUES (1), (2);

-- Query
SELECT e.employee_id, d.department_head
FROM employees e
JOIN departments d ON e.department_id = d.department_id;

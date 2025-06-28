-- Create a table and populate it with initial values

CREATE TABLE employees (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100),
    department VARCHAR(100)
);

INSERT INTO employees (name, department) VALUES
('Alice', 'HR'),
('Bob', 'Engineering'),
('Charlie', 'Sales');

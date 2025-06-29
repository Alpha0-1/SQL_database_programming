-- =============================================================================
-- File: 3-upsert.sql
-- Description: UPSERT operations (INSERT ... ON DUPLICATE KEY UPDATE)
-- Author: Alpha0-1
-- =============================================================================

-- =============================================================================
-- SETUP: Create tables for UPSERT examples
-- =============================================================================

-- Main employees table with unique constraints
CREATE TABLE IF NOT EXISTS employees (
    id INT AUTO_INCREMENT PRIMARY KEY,
    employee_id VARCHAR(10) UNIQUE NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    department VARCHAR(50),
    salary DECIMAL(10,2),
    hire_date DATE,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    update_count INT DEFAULT 0
);

-- Products table for inventory management example
CREATE TABLE IF NOT EXISTS products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_code VARCHAR(20) UNIQUE NOT NULL,
    product_name VARCHAR(100) NOT NULL,
    price DECIMAL(10,2),
    stock_quantity INT DEFAULT 0,
    last_restocked DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Customer data table for CRM example
CREATE TABLE IF NOT EXISTS customers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id VARCHAR(20) UNIQUE NOT NULL,
    company_name VARCHAR(100),
    contact_email VARCHAR(100) UNIQUE,
    phone VARCHAR(20),
    total_orders INT DEFAULT 0,
    total_spent DECIMAL(12,2) DEFAULT 0.00,
    last_order_date DATE,
    status VARCHAR(20) DEFAULT 'Active'
);

-- =============================================================================
-- METHOD 1: BASIC UPSERT WITH ON DUPLICATE KEY UPDATE
-- =============================================================================

-- Insert new employees or update existing ones
INSERT INTO employees (employee_id, first_name, last_name, email, department, salary, hire_date)
VALUES 
    ('EMP001', 'John', 'Doe', 'john.doe@company.com', 'Engineering', 75000.00, '2024-01-15'),
    ('EMP002', 'Jane', 'Smith', 'jane.smith@company.com', 'Marketing', 65000.00, '2024-01-20'),
    ('EMP003', 'Mike', 'Johnson', 'mike.johnson@company.com', 'Sales', 70000.00, '2024-02-01')
ON DUPLICATE KEY UPDATE
    first_name = VALUES(first_name),
    last_name = VALUES(last_name),
    department = VALUES(department),
    salary = VALUES(salary),
    update_count = update_count + 1;

-- Verify the initial insert
SELECT * FROM employees ORDER BY employee_id;

-- =============================================================================
-- METHOD 2: CONDITIONAL UPSERT (Only Update if New Data is Different)
-- =============================================================================

-- Update only if the new salary is higher or department changed
INSERT INTO employees (employee_id, first_name, last_name, email, department, salary, hire_date)
VALUES 
    ('EMP001', 'John', 'Doe', 'john.doe@company.com', 'Senior Engineering', 80000.00, '2024-01-15'),
    ('EMP004', 'Sarah', 'Wilson', 'sarah.wilson@company.com', 'HR', 60000.00, '2024-02-10')
ON DUPLICATE KEY UPDATE
    department = IF(VALUES(department) != department, VALUES(department), department),
    salary = IF(VALUES(salary) > salary, VALUES(salary), salary),
    first_name = VALUES(first_name),
    last_name = VALUES(last_name),
    update_count = update_count + 1;

-- =============================================================================
-- METHOD 3: INVENTORY MANAGEMENT UPSERT
-- =============================================================================

-- Upsert product inventory - add new products or update stock
INSERT INTO products (product_code, product_name, price, stock_quantity, last_restocked)
VALUES 
    ('LAPTOP001', 'Dell Latitude 5520', 1299.99, 50, CURDATE()),
    ('MOUSE001', 'Logitech MX Master 3', 99.99, 200, CURDATE()),
    ('KEYBOARD001', 'Mechanical Keyboard RGB', 159.99, 75, CURDATE()),
    ('MONITOR001', 'Samsung 27" 4K Monitor', 399.99, 30, CURDATE())
ON DUPLICATE KEY UPDATE
    product_name = VALUES(product_name),
    price = VALUES(price),
    stock_quantity = stock_quantity + VALUES(stock_quantity),  -- Add to existing stock
    last_restocked = VALUES(last_restocked);

-- Add more stock to existing products
INSERT INTO products (product_code, product_name, price, stock_quantity, last_restocked)
VALUES 
    ('LAPTOP001', 'Dell Latitude 5520', 1299.99, 25, CURDATE()),  -- Add 25 more laptops
    ('MOUSE001', 'Logitech MX Master 3', 89.99, 100, CURDATE())   -- Add 100 mice, update price
ON DUPLICATE KEY UPDATE
    price = IF(VALUES(price) < price, VALUES(price), price),  -- Keep lower price
    stock_quantity = stock_quantity + VALUES(stock_quantity),
    last_restocked = VALUES(last_restocked);

-- View updated inventory
SELECT product_code, product_name, price, stock_quantity, last_restocked 
FROM products ORDER BY product_code;

-- =============================================================================
-- METHOD 4: CUSTOMER DATA UPSERT (CRM System)
-- =============================================================================

-- Upsert customer data from various sources
INSERT INTO customers (customer_id, company_name, contact_email, phone, total_orders, total_spent, last_order_date)
VALUES 
    ('CUST001', 'TechCorp Inc', 'contact@techcorp.com', '+1-555-0101', 5, 15000.00, '2024-06-15'),
    ('CUST002', 'DataSystems LLC', 'info@datasystems.com', '+1-555-0102', 3, 8500.00, '2024-06-10'),
    ('CUST003', 'CloudFirst Solutions', 'hello@cloudfirst.com', '+1-555-0103', 1, 2500.00, '2024-06-20')
ON DUPLICATE KEY UPDATE
    company_name = COALESCE(VALUES(company_name), company_name),  -- Keep existing if new is NULL
    contact_email = VALUES(contact_email),
    phone = COALESCE(VALUES(phone), phone),
    total_orders = total_orders + VALUES(total_orders),
    total_spent = total_spent + VALUES(total_spent),
    last_order_date = GREATEST(last_order_date, VALUES(last_order_date)),  -- Keep latest date
    status = IF(VALUES(last_order_date) > DATE_SUB(CURDATE(), INTERVAL 90 DAY), 'Active', status);

-- =============================================================================
-- METHOD 5: BULK UPSERT FROM EXTERNAL DATA SOURCE
-- =============================================================================

-- Create temporary table simulating external data feed
CREATE TEMPORARY TABLE employee_updates (
    employee_id VARCHAR(10),
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    department VARCHAR(50),
    salary DECIMAL(10,2),
    performance_rating VARCHAR(20)
);

-- Insert sample external data
INSERT INTO employee_updates VALUES
    ('EMP001', 'John', 'Doe', 'john.doe@company.com', 'Senior Engineering', 85000.00, 'Excellent'),
    ('EMP002', 'Jane', 'Smith', 'jane.smith@company.com', 'Marketing Manager', 72000.00, 'Very Good'),
    ('EMP005', 'David', 'Brown', 'david.brown@company.com', 'Finance', 68000.00, 'Good'),
    ('EMP006', 'Lisa', 'Garcia', 'lisa.garcia@company.com', 'Engineering', 77000.00, 'Excellent');

-- Add performance_rating column to employees table
ALTER TABLE employees ADD COLUMN IF NOT EXISTS performance_rating VARCHAR(20);

-- Bulk upsert from external source
INSERT INTO employees (employee_id, first_name, last_name, email, department, salary, performance_rating, hire_date)
SELECT 
    employee_id,
    first_name,
    last_name,
    email,
    department,
    salary,
    performance_rating,
    CURDATE()  -- Default hire date for new employees
FROM employee_updates
ON DUPLICATE KEY UPDATE
    first_name = VALUES(first_name),
    last_name = VALUES(last_name),
    department = VALUES(department),
    salary = GREATEST(salary, VALUES(salary)),  -- Only increase salary
    performance_rating = VALUES(performance_rating),
    update_count = update_count + 1;

-- =============================================================================
-- METHOD 6: UPSERT WITH COMPLEX BUSINESS LOGIC
-- =============================================================================

-- Upsert with calculated values and business rules
INSERT INTO customers (customer_id, company_name, contact_email, phone, total_orders, total_spent, last_order_date)
VALUES 
    ('CUST001', 'TechCorp Inc', 'contact@techcorp.com', '+1-555-0101', 2, 5000.00, '2024-06-25'),
    ('CUST004', 'NewTech Startup', 'admin@newtech.com', '+1-555-0104', 1, 1200.00, '2024-06-22')
ON DUPLICATE KEY UPDATE
    total_orders = total_orders + VALUES(total_orders),
    total_spent = total_spent + VALUES(total_spent),
    last_order_date = GREATEST(last_order_date, VALUES(last_order_date)),
    status = CASE 
        WHEN total_spent + VALUES(total_spent) > 20000 THEN 'Premium'
        WHEN total_spent + VALUES(total_spent) > 10000 THEN 'Gold'
        WHEN GREATEST(last_order_date, VALUES(last_order_date)) > DATE_SUB(CURDATE(), INTERVAL 30 DAY) THEN 'Active'
        ELSE 'Standard'
    END;

-- =============================================================================
-- METHOD 7: UPSERT WITH JSON DATA HANDLING
-- =============================================================================

-- Add JSON column for flexible data storage
ALTER TABLE employees ADD COLUMN IF NOT EXISTS metadata JSON;

-- Upsert with JSON data
INSERT INTO employees (employee_id, first_name, last_name, email, department, salary, hire_date, metadata)
VALUES 
    ('EMP007', 'Alex', 'Johnson', 'alex.johnson@company.com', 'DevOps', 82000.00, '2024-03-01',
     JSON_OBJECT('skills', JSON_ARRAY('Docker', 'Kubernetes', 'AWS'), 'certifications', JSON_ARRAY('AWS Solutions Architect'), 'remote_work', true)),
    ('EMP001', 'John', 'Doe', 'john.doe@company.com', 'Senior Engineering', 85000.00, '2024-01-15',
     JSON_OBJECT('skills', JSON_ARRAY('Python', 'SQL', 'Machine Learning'), 'team_lead', true))
ON DUPLICATE KEY UPDATE
    first_name = VALUES(first_name),
    last_name = VALUES(last_name),
    department = VALUES(department),
    salary = VALUES(salary),
    metadata = CASE 
        WHEN metadata IS NULL THEN VALUES(metadata)
        ELSE JSON_MERGE_PATCH(metadata, VALUES(metadata))
    END,
    update_count = update_count + 1;

-- =============================================================================
-- METHOD 8: REPLACE STATEMENT (Alternative to UPSERT)
-- =============================================================================

-- REPLACE is equivalent to DELETE + INSERT
-- Use with caution as it removes the entire row first

REPLACE INTO products (product_code, product_name, price, stock_quantity, last_restocked)
VALUES 
    ('TABLET001', 'iPad Pro 12.9"', 1099.99, 40, CURDATE()),
    ('LAPTOP001', 'Dell Latitude 5520', 1199.99, 60, CURDATE());  -- This will replace existing laptop record

-- =============================================================================
-- VERIFICATION AND MONITORING
-- =============================================================================

-- Check all employees and their update counts
SELECT 
    employee_id,
    CONCAT(first_name, ' ', last_name) as full_name,
    department,
    salary,
    performance_rating,
    update_count,
    last_updated
FROM employees 
ORDER BY employee_id;

-- Verify product inventory
SELECT 
    product_code,
    product_name,
    price,
    stock_quantity,
    last_restocked,
    CASE 
        WHEN stock_quantity < 20 THEN 'Low Stock'
        WHEN stock_quantity < 50 THEN 'Medium Stock'
        ELSE 'High Stock'
    END as stock_status
FROM products
ORDER BY stock_quantity;

-- Check customer statistics
SELECT 
    customer_id,
    company_name,
    total_orders,
    total_spent,
    status,
    DATEDIFF(CURDATE(), last_order_date) as days_since_last_order
FROM customers
ORDER BY total_spent DESC;

-- =============================================================================
-- PERFORMANCE OPTIMIZATION FOR UPSERTS
-- =============================================================================

-- Create indexes for better upsert performance
CREATE INDEX IF NOT EXISTS idx_employee_id ON employees(employee_id);
CREATE INDEX IF NOT EXISTS idx_employee_email ON employees(email);
CREATE INDEX IF NOT EXISTS idx_product_code ON products(product_code);
CREATE INDEX IF NOT EXISTS idx_customer_id ON customers(customer_id);

-- Monitor upsert performance
EXPLAIN FORMAT=JSON
INSERT INTO employees (employee_id, first_name, last_name, email, department, salary)
VALUES ('EMP999', 'Test', 'User', 'test@company.com', 'Testing', 50000.00)
ON DUPLICATE KEY UPDATE
    salary = VALUES(salary),
    update_count = update_count + 1;

-- =============================================================================
-- ERROR HANDLING AND VALIDATION
-- =============================================================================

-- Upsert with validation and error handling
INSERT INTO employees (employee_id, first_name, last_name, email, department, salary, hire_date)
SELECT 
    'EMP008',
    'Invalid',
    'Employee',
    CASE 
        WHEN 'invalid-email' LIKE '%@%.%' THEN 'invalid-email'
        ELSE CONCAT('fixed-', UUID(), '@company.com')
    END,
    'QA',
    CASE 
        WHEN 30000 BETWEEN 40000 AND 200000 THEN 30000
        ELSE 50000  -- Default minimum salary
    END,
    CASE 
        WHEN '2025-01-01' <= CURDATE() THEN CURDATE()
        ELSE '2025-01-01'
    END
ON DUPLICATE KEY UPDATE
    salary = CASE 
        WHEN VALUES(salary) BETWEEN 40000 AND 200000 THEN VALUES(salary)
        ELSE salary  -- Keep existing salary if new one is invalid
    END,
    update_count = update_count + 1;

-- =============================================================================
-- CLEANUP
-- =============================================================================

-- Drop temporary table
DROP TEMPORARY TABLE IF EXISTS employee_updates;

-- =============================================================================
-- BEST PRACTICES SUMMARY
-- =============================================================================

/*
UPSERT BEST PRACTICES:

1. UNDERSTAND YOUR CONSTRAINTS
   - Know which columns have UNIQUE constraints
   - Understand the difference between PRIMARY KEY and UNIQUE constraints
   - Test with small datasets first

2. USE APPROPRIATE UPDATE LOGIC
   - VALUES(column) references the new value being inserted
   - Use conditional logic (IF, CASE) for complex business rules
   - Consider using GREATEST/LEAST for comparative updates

3. PERFORMANCE CONSIDERATIONS
   - Ensure proper indexing on unique columns
   - Use bulk upserts instead of single-row operations
   - Monitor query performance and execution plans

4. DATA INTEGRITY
   - Validate data before upsert operations
   - Use transactions for critical operations
   - Handle NULL values appropriately with COALESCE

5. ALTERNATIVES TO CONSIDER
   - INSERT IGNORE: Insert only if doesn't exist (no update)
   - REPLACE: Delete existing and insert new (loses other column data)
   - Manual INSERT + UPDATE with error handling

6. COMMON PITFALLS TO AVOID
   - Don't forget ON DUPLICATE KEY UPDATE clause
   - Be careful with calculated values (they execute on both INSERT and UPDATE)
   - Remember that AUTO_INCREMENT values are consumed even when updating
   - Test edge cases (NULL values, boundary conditions)

7. MONITORING AND DEBUGGING
   - Track update counts to monitor data changes
   - Use timestamps to track when records were modified
   - Log upsert operations for audit purposes
   - Verify results after bulk operations

8. DATABASE COMPATIBILITY
   - MySQL: ON DUPLICATE KEY UPDATE
   - PostgreSQL: ON CONFLICT DO UPDATE
   - SQL Server: MERGE statement
   - SQLite: ON CONFLICT REPLACE/UPDATE
*/

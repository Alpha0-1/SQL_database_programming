-- MySQL Built-in Functions Examples

-- Sample table creation
CREATE TABLE sales (
    sale_id INT PRIMARY KEY,
    amount DECIMAL(10,2),
    sale_date DATE
);

-- Insert sample sales data
INSERT INTO sales VALUES
    (1, 100.00, '2023-01-01'),
    (2, 200.00, '2023-01-02'),
    (3, 150.00, '2023-01-03');

-- Aggregate functions
SELECT COUNT(*) AS total_sales, SUM(amount) AS total_revenue, AVG(amount) AS avg_sale
FROM sales;

-- Date functions
SELECT sale_date, DAYNAME(sale_date) AS day_of_week
FROM sales;

-- String function example
SELECT CONCAT('Sale #', sale_id) AS sale_label FROM sales;

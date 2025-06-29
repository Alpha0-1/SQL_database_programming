-- File: 2-correlation_analysis.sql
-- Description: Calculate correlation between two numeric fields

-- Create a sample customer engagement table
CREATE TABLE IF NOT EXISTS customer_engagement (
    id SERIAL PRIMARY KEY,
    customer_id INT,
    visits INT,
    purchases INT
);

-- Insert sample data
INSERT INTO customer_engagement (customer_id, visits, purchases)
VALUES 
(1, 10, 2),
(2, 15, 3),
(3, 20, 5),
(4, 25, 7),
(5, 30, 9);

-- Calculate correlation coefficient using PostgreSQL
SELECT CORR(visits, purchases) AS visit_purchase_correlation FROM customer_engagement;


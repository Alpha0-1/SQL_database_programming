-- File: 4-cohort_analysis.sql
-- Description: Perform basic cohort analysis by customer signup month

-- Create a mock user signup and purchase table
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    signup_date DATE
);

CREATE TABLE IF NOT EXISTS purchases (
    id SERIAL PRIMARY KEY,
    user_id INT,
    purchase_date DATE,
    amount DECIMAL(10,2)
);

-- Cohort analysis: Group users by signup month and count purchases by cohort
SELECT 
    DATE_TRUNC('month', u.signup_date) AS cohort_month,
    DATE_TRUNC('month', p.purchase_date) AS purchase_month,
    COUNT(p.id) AS total_purchases
FROM 
    users u
JOIN 
    purchases p ON u.id = p.user_id
GROUP BY 
    cohort_month, purchase_month
ORDER BY 
    cohort_month, purchase_month;


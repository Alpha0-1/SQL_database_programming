-- 6-retention_analysis.sql
-- Measure customer retention rate over time

-- Example: Monthly retention rate of customers who made a purchase
WITH first_purchase AS (
    SELECT customer_id, DATE_TRUNC('month', MIN(purchase_date)) AS first_month
    FROM purchases
    GROUP BY customer_id
),
retained_customers AS (
    SELECT
        fp.first_month,
        DATE_TRUNC('month', p.purchase_date) AS return_month,
        COUNT(DISTINCT fp.customer_id) AS retained_count
    FROM first_purchase fp
    JOIN purchases p ON fp.customer_id = p.customer_id
    WHERE p.purchase_date > fp.purchase_date
    GROUP BY fp.first_month, DATE_TRUNC('month', p.purchase_date)
)
SELECT *
FROM retained_customers
ORDER BY first_month, return_month;

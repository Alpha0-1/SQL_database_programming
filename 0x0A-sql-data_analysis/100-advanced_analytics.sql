-- File: 100-advanced_analytics.sql
-- Description: Complex window functions, nested queries, and CTEs

-- Rank customers by total spend with cumulative spend
WITH ranked AS (
    SELECT 
        customer_id,
        SUM(amount) AS total_spent,
        RANK() OVER (ORDER BY SUM(amount) DESC) AS rank,
        SUM(SUM(amount)) OVER (ORDER BY SUM(amount) DESC ROWS UNBOUNDED PRECEDING) AS cumulative
    FROM sales
    GROUP BY customer_id
)
SELECT * FROM ranked;

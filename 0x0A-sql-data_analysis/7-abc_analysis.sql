-- 7-abc_analysis.sql
-- Classify products into A, B, C categories based on revenue contribution

-- Example: Product classification by total sales
WITH product_revenue AS (
    SELECT product_id, SUM(amount) AS total_revenue
    FROM sales
    GROUP BY product_id
),
cumulative_revenue AS (
    SELECT *,
           SUM(total_revenue) OVER (ORDER BY total_revenue DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) / SUM(total_revenue) OVER () * 100 AS cumulative_percent
FROM (
    SELECT *, total_revenue
    FROM product_revenue
    ORDER BY total_revenue DESC
) ranked
)
SELECT
    product_id,
    total_revenue,
    CASE
        WHEN cumulative_percent <= 70 THEN 'A'
        WHEN cumulative_percent <= 90 THEN 'B'
        ELSE 'C'
    END AS abc_class
FROM cumulative_revenue;

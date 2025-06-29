-- 8-seasonal_analysis.sql
-- Identify seasonal patterns in sales or usage

-- Example: Monthly average sales to detect seasonality
SELECT
    EXTRACT(MONTH FROM sale_date) AS month,
    AVG(amount) AS avg_sales
FROM sales
GROUP BY month
ORDER BY month;

-- File: 3-trend_analysis.sql
-- Description: Identify trends over time in sales data

-- Aggregate sales by day to detect trend
SELECT 
    sale_date,
    SUM(amount) AS daily_total
FROM 
    sales
GROUP BY 
    sale_date
ORDER BY 
    sale_date;


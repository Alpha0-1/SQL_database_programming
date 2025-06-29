-- 11-time_series_analysis.sql
-- Basic time series operations like moving averages

-- Example: 7-day moving average of sales
SELECT
    sale_date,
    amount,
    AVG(amount) OVER (ORDER BY sale_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS moving_avg_7d
FROM sales
ORDER BY sale_date;

-- 12-forecasting.sql
-- Simple forecasting using linear extrapolation

-- Forecast next 3 months based on past 6 months of sales
WITH monthly_sales AS (
    SELECT
        DATE_TRUNC('month', sale_date) AS month,
        SUM(amount) AS total_sales
    FROM sales
    WHERE sale_date >= CURRENT_DATE - INTERVAL '6 months'
    GROUP BY month
),
regression_stats AS (
    SELECT
        COUNT(*) AS n,
        AVG(EXTRACT(EPOCH FROM month)) AS x_avg,
        AVG(total_sales) AS y_avg,
        SUM((EXTRACT(EPOCH FROM month) - x_avg) * (total_sales - y_avg)) AS numerator,
        SUM((EXTRACT(EPOCH FROM month) - x_avg)^2) AS denominator
    FROM monthly_sales
),
coefficients AS (
    SELECT
        numerator / NULLIF(denominator, 0) AS slope,
        y_avg - (numerator / NULLIF(denominator, 0)) * x_avg AS intercept
    FROM regression_stats
)
-- Forecast next 3 months
SELECT
    generate_series AS future_month,
    slope * EXTRACT(EPOCH FROM generate_series) + intercept AS forecasted_sales
FROM coefficients,
     GENERATE_SERIES(
         (SELECT MAX(month) FROM monthly_sales) + INTERVAL '1 month',
         (SELECT MAX(month) FROM monthly_sales) + INTERVAL '3 months',
         INTERVAL '1 month'
     );

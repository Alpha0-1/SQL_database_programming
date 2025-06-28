-- 103-complex_analytics.sql
-- Purpose: Demonstrate complex analytical queries
-- Author: Alpha0-1

-- Sales data with dates
CREATE TABLE IF NOT EXISTS daily_sales (
    sale_date DATE,
    amount NUMERIC(10,2)
);

-- Insert sample data
INSERT INTO daily_sales (sale_date, amount) VALUES
('2023-01-01', 100), ('2023-01-02', 150), ('2023-01-03', 200);

-- Rolling average over 2 days
SELECT
    sale_date,
    amount,
    AVG(amount) OVER (
        ORDER BY sale_date
        ROWS BETWEEN 1 PRECEDING AND CURRENT ROW
    ) AS rolling_avg_2_days
FROM daily_sales;

-- Year-over-year growth
SELECT
    EXTRACT(YEAR FROM sale_date) AS year,
    SUM(amount) AS total_sales,
    LAG(SUM(amount), 1) OVER (ORDER BY EXTRACT(YEAR FROM sale_date)) AS prev_year_sales,
    (SUM(amount) - LAG(SUM(amount), 1) OVER ()) / LAG(SUM(amount), 1) OVER () * 100 AS yoy_growth_percent
FROM daily_sales
GROUP BY year;

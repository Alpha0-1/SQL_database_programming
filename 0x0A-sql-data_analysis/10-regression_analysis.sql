-- 10-regression_analysis.sql - Linear regression analysis

-- Example data table (drop if exists)
DROP TABLE IF EXISTS advertising_revenue;
CREATE TABLE advertising_revenue (
    ad_spend DECIMAL(10,2),
    sales DECIMAL(10,2)
);

-- Insert sample data
INSERT INTO advertising_revenue VALUES
(1000.00, 5000.00),
(1500.00, 6500.00),
(1200.00, 6000.00),
(2000.00, 8000.00),
(800.00, 4000.00);

-- Simple Linear Regression
WITH SumComponents AS (
    SELECT
        COUNT(*) AS n,
        SUM(ad_spend) AS sum_x,
        SUM(sales) AS sum_y,
        SUM(ad_spend * sales) AS sum_xy,
        SUM(ad_spend^2) AS sum_x_squared
    FROM advertising_revenue
)
SELECT
    (sum_xy - (sum_x * sum_y) / n) / (sum_x_squared - (sum_x^2)/n) AS slope,
    (sum_y / n) - slope * (sum_x / n) AS intercept
FROM SumComponents;

-- Cleanup (optional)
-- DROP TABLE advertising_revenue;

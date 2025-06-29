-- 9-outlier_detection.sql
-- Detect outliers using statistical methods like Z-score or IQR

-- Using Z-score method
WITH stats AS (
    SELECT
        AVG(amount) AS mean,
        STDDEV(amount) AS stddev
    FROM sales
)
SELECT *
FROM sales, stats
WHERE ABS((amount - mean) / stddev) > 3; -- Outliers more than 3 SD away

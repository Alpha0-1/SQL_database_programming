-- File: 1-data_distribution.sql
-- Description: Analyze data distribution using frequency counts and percentiles

-- Frequency distribution of sale amounts (rounded to nearest 50)
SELECT 
    ROUND(amount / 50) * 50 AS amount_group,
    COUNT(*) AS frequency
FROM 
    sales
GROUP BY 
    amount_group
ORDER BY 
    amount_group;

-- Percentile analysis using PostgreSQL's percentile_cont function
-- Calculates the 25th, 50th (median), and 75th percentiles
SELECT 
    percentile_cont(ARRAY[0.25, 0.5, 0.75]) WITHIN GROUP (ORDER BY amount) AS percentiles
FROM 
    sales;

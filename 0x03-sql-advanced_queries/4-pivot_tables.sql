-- File: 4-pivot_tables.sql
-- Description: Creating pivot tables and cross-tabulations in SQL
-- Author: Alpha0-1
-- Date: 2025

-- Pivot tables transform rows into columns for better data analysis
-- Different databases have different pivot syntax, this shows common patterns

-- Sample data: Monthly sales by product and region
CREATE TABLE IF NOT EXISTS monthly_sales (
    id INT PRIMARY KEY,
    product VARCHAR(50),
    region VARCHAR(50),
    month VARCHAR(7), -- YYYY-MM format
    sales_amount DECIMAL(10,2)
);

INSERT INTO monthly_sales VALUES
(1, 'Product A', 'North', '2024-01', 15000.00),
(2, 'Product A', 'South', '2024-01', 12000.00),
(3, 'Product A', 'East', '2024-01', 18000.00),
(4, 'Product A', 'West', '2024-01', 14000.00),
(5, 'Product B', 'North', '2024-01', 20000.00),
(6, 'Product B', 'South', '2024-01', 22000.00),
(7, 'Product B', 'East', '2024-01', 19000.00),
(8, 'Product B', 'West', '2024-01', 21000.00),
(9, 'Product A', 'North', '2024-02', 16000.00),
(10, 'Product A', 'South', '2024-02', 13000.00),
(11, 'Product A', 'East', '2024-02', 17000.00),
(12, 'Product A', 'West', '2024-02', 15000.00),
(13, 'Product B', 'North', '2024-02', 21000.00),
(14, 'Product B', 'South', '2024-02', 23000.00),
(15, 'Product B', 'East', '2024-02', 20000.00),
(16, 'Product B', 'West', '2024-02', 22000.00),
(17, 'Product C', 'North', '2024-01', 8000.00),
(18, 'Product C', 'South', '2024-01', 9000.00),
(19, 'Product C', 'East', '2024-01', 7500.00),
(20, 'Product C', 'West', '2024-01', 8500.00);

-- 1. Basic pivot using CASE statements (works in all databases)
-- Pivot regions as columns for each product
SELECT 
    product,
    SUM(CASE WHEN region = 'North' THEN sales_amount ELSE 0 END) as North,
    SUM(CASE WHEN region = 'South' THEN sales_amount ELSE 0 END) as South,
    SUM(CASE WHEN region = 'East' THEN sales_amount ELSE 0 END) as East,
    SUM(CASE WHEN region = 'West' THEN sales_amount ELSE 0 END) as West,
    SUM(sales_amount) as Total
FROM monthly_sales
GROUP BY product
ORDER BY product;

-- 2. Pivot with multiple aggregations
SELECT 
    product,
    -- Sum by region
    SUM(CASE WHEN region = 'North' THEN sales_amount ELSE 0 END) as North_Sales,
    SUM(CASE WHEN region = 'South' THEN sales_amount ELSE 0 END) as South_Sales,
    SUM(CASE WHEN region = 'East' THEN sales_amount ELSE 0 END) as East_Sales,
    SUM(CASE WHEN region = 'West' THEN sales_amount ELSE 0 END) as West_Sales,
    -- Count by region
    COUNT(CASE WHEN region = 'North' THEN 1 END) as North_Count,
    COUNT(CASE WHEN region = 'South' THEN 1 END) as South_Count,
    COUNT(CASE WHEN region = 'East' THEN 1 END) as East_Count,
    COUNT(CASE WHEN region = 'West' THEN 1 END) as West_Count,
    -- Average by region
    AVG(CASE WHEN region = 'North' THEN sales_amount END) as North_Avg,
    AVG(CASE WHEN region = 'South' THEN sales_amount END) as South_Avg,
    AVG(CASE WHEN region = 'East' THEN sales_amount END) as East_Avg,
    AVG(CASE WHEN region = 'West' THEN sales_amount END) as West_Avg
FROM monthly_sales
GROUP BY product
ORDER BY product;

-- 3. Time-based pivot (months as columns)
SELECT 
    product,
    region,
    SUM(CASE WHEN month = '2024-01' THEN sales_amount ELSE 0 END) as Jan_2024,
    SUM(CASE WHEN month = '2024-02' THEN sales_amount ELSE 0 END) as Feb_2024,
    -- Calculate month-over-month change
    SUM(CASE WHEN month = '2024-02' THEN sales_amount ELSE 0 END) - 
    SUM(CASE WHEN month = '2024-01' THEN sales_amount ELSE 0 END) as MoM_Change,
    -- Calculate percentage change
    CASE 
        WHEN SUM(CASE WHEN month = '2024-01' THEN sales_amount ELSE 0 END) > 0 THEN
            ROUND(
                (SUM(CASE WHEN month = '2024-02' THEN sales_amount ELSE 0 END) - 
                 SUM(CASE WHEN month = '2024-01' THEN sales_amount ELSE 0 END)) * 100.0 /
                SUM(CASE WHEN month = '2024-01' THEN sales_amount ELSE 0 END),
                2
            )
        ELSE NULL
    END as MoM_Pct_Change
FROM monthly_sales
GROUP BY product, region
ORDER BY product, region;

-- 4. Dynamic pivot using conditional aggregation
-- Pivot all unique regions without hardcoding
WITH region_list AS (
    SELECT DISTINCT region FROM monthly_sales ORDER BY region
),
pivot_data AS (
    SELECT 
        product,
        month,
        MAX(CASE WHEN region = 'East' THEN sales_amount END) as East,
        MAX(CASE WHEN region = 'North' THEN sales_amount END) as North,
        MAX(CASE WHEN region = 'South' THEN sales_amount END) as South,
        MAX(CASE WHEN region = 'West' THEN sales_amount END) as West
    FROM monthly_sales
    GROUP BY product, month
)
SELECT 
    product,
    month,
    COALESCE(East, 0) as East,
    COALESCE(North, 0) as North,
    COALESCE(South, 0) as South,
    COALESCE(West, 0) as West,
    COALESCE(East, 0) + COALESCE(North, 0) + COALESCE(South, 0) + COALESCE(West, 0) as Total
FROM pivot_data
ORDER BY product, month;

-- 5. Crosstab with percentages
SELECT 
    product,
    -- Sales amounts
    SUM(CASE WHEN region = 'North' THEN sales_amount ELSE 0 END) as North_Sales,
    SUM(CASE WHEN region = 'South' THEN sales_amount ELSE 0 END) as South_Sales,
    SUM(CASE WHEN region = 'East' THEN sales_amount ELSE 0 END) as East_Sales,
    SUM(CASE WHEN region = 'West' THEN sales_amount ELSE 0 END) as West_Sales,
    -- Percentages of total
    ROUND(
        SUM(CASE WHEN region = 'North' THEN sales_amount ELSE 0 END) * 100.0 / 
        SUM(sales_amount), 2
    ) as North_Pct,
    ROUND(
        SUM(CASE WHEN region = 'South' THEN sales_amount ELSE 0 END) * 100.0 / 
        SUM(sales_amount), 2
    ) as South_Pct,
    ROUND(
        SUM(CASE WHEN region = 'East' THEN sales_amount ELSE 0 END) * 100.0 / 
        SUM(sales_amount), 2
    ) as East_Pct,
    ROUND(
        SUM(CASE WHEN region = 'West' THEN sales_amount ELSE 0 END) * 100.0 / 
        SUM(sales_amount), 2
    ) as West_Pct,
    SUM(sales_amount) as Total_Sales
FROM monthly_sales
GROUP BY product
ORDER BY product;

-- 6. Multi-level pivot (product and month as rows, regions as columns)
SELECT 
    product,
    month,
    SUM(CASE WHEN region = 'North' THEN sales_amount END) as North,
    SUM(CASE WHEN region = 'South' THEN sales_amount END) as South,
    SUM(CASE WHEN region = 'East' THEN sales_amount END) as East,
    SUM(CASE WHEN region = 'West' THEN sales_amount END) as West,
    SUM(sales_amount) as Row_Total
FROM monthly_sales
GROUP BY product, month
UNION ALL
-- Add subtotals for each product
SELECT 
    product,
    'TOTAL' as month,
    SUM(CASE WHEN region = 'North' THEN sales_amount END) as North,
    SUM(CASE WHEN region = 'South' THEN sales_amount END) as South,
    SUM(CASE WHEN region = 'East' THEN sales_amount END) as East,
    SUM(CASE WHEN region = 'West' THEN sales_amount END) as West,
    SUM(sales_amount) as Row_Total
FROM monthly_sales
GROUP BY product
ORDER BY product, 
         CASE WHEN month = 'TOTAL' THEN 'ZZZZ' ELSE month END;

-- 7. Pivot with conditional formatting flags
SELECT 
    product,
    SUM(CASE WHEN region = 'North' THEN sales_amount ELSE 0 END) as North,
    SUM(CASE WHEN region = 'South' THEN sales_amount ELSE 0 END) as South,
    SUM(CASE WHEN region = 'East' THEN sales_amount ELSE 0 END) as East,
    SUM(CASE WHEN region = 'West' THEN sales_amount ELSE 0 END) as West,
    -- Flag best performing region
    CASE 
        WHEN SUM(CASE WHEN region = 'North' THEN sales_amount ELSE 0 END) = 
             GREATEST(
                 SUM(CASE WHEN region = 'North' THEN sales_amount ELSE 0 END),
                 SUM(CASE WHEN region = 'South' THEN sales_amount ELSE 0 END),
                 SUM(CASE WHEN region = 'East' THEN sales_amount ELSE 0 END),
                 SUM(CASE WHEN region = 'West' THEN sales_amount ELSE 0 END)
             ) THEN 'North'
        WHEN SUM(CASE WHEN region = 'South' THEN sales_amount ELSE 0 END) = 
             GREATEST(
                 SUM(CASE WHEN region = 'North' THEN sales_amount ELSE 0 END),
                 SUM(CASE WHEN region = 'South' THEN sales_amount ELSE 0 END),
                 SUM(CASE WHEN region = 'East' THEN sales_amount ELSE 0 END),
                 SUM(CASE WHEN region = 'West' THEN sales_amount ELSE 0 END)
             ) THEN 'South'
        WHEN SUM(CASE WHEN region = 'East' THEN sales_amount ELSE 0 END) = 
             GREATEST(
                 SUM(CASE WHEN region = 'North' THEN sales_amount ELSE 0 END),
                 SUM(CASE WHEN region = 'South' THEN sales_amount ELSE 0 END),
                 SUM(CASE WHEN region = 'East' THEN sales_amount ELSE 0 END),
                 SUM(CASE WHEN region = 'West' THEN sales_amount ELSE 0 END)
             ) THEN 'East'
        ELSE 'West'
    END as Best_Region
FROM monthly_sales
GROUP BY product
ORDER BY product;

-- 8. Unpivot example (convert columns back to rows)
-- First create a pivoted table
CREATE TABLE IF NOT EXISTS pivoted_sales AS
SELECT 
    product,
    SUM(CASE WHEN region = 'North' THEN sales_amount ELSE 0 END) as North,
    SUM(CASE WHEN region = 'South' THEN sales_amount ELSE 0 END) as South,
    SUM(CASE WHEN region = 'East' THEN sales_amount ELSE 0 END) as East,
    SUM(CASE WHEN region = 'West' THEN sales_amount ELSE 0 END) as West
FROM monthly_sales
GROUP BY product;

-- Unpivot back to normalized form
SELECT product, 'North' as region, North as sales_amount FROM pivoted_sales WHERE North > 0
UNION ALL
SELECT product, 'South' as region, South as sales_amount FROM pivoted_sales WHERE South > 0
UNION ALL
SELECT product, 'East' as region, East as sales_amount FROM pivoted_sales WHERE East > 0
UNION ALL
SELECT product, 'West' as region, West as sales_amount FROM pivoted_sales WHERE West > 0
ORDER BY product, region;

-- 9. Advanced pivot with rankings
WITH regional_totals AS (
    SELECT 
        product,
        SUM(CASE WHEN region = 'North' THEN sales_amount ELSE 0 END) as North,
        SUM(CASE WHEN region = 'South' THEN sales_amount ELSE 0 END) as South,
        SUM(CASE WHEN region = 'East' THEN sales_amount ELSE 0 END) as East,
        SUM(CASE WHEN region = 'West' THEN sales_amount ELSE 0 END) as West,
        SUM(sales_amount) as Total
    FROM monthly_sales
    GROUP BY product
)
SELECT 
    product,
    North,
    South,
    East,
    West,
    Total,
    -- Rank products by total sales
    RANK() OVER(ORDER BY Total DESC) as Product_Rank,
    -- Rank each region within product
    RANK() OVER(PARTITION BY product ORDER BY North DESC) as North_Rank_in_Product,
    RANK() OVER(PARTITION BY product ORDER BY South DESC) as South_Rank_in_Product,
    RANK() OVER(PARTITION BY product ORDER BY East DESC) as East_Rank_in_Product,
    RANK() OVER(PARTITION BY product ORDER BY West DESC) as West_Rank_in_Product
FROM regional_totals
ORDER BY Product_Rank;

-- 10. Pivot with statistical measures
SELECT 
    product,
    -- Regional sales
    SUM(CASE WHEN region = 'North' THEN sales_amount ELSE 0 END) as North,
    SUM(CASE WHEN region = 'South' THEN sales_amount ELSE 0 END) as South,
    SUM(CASE WHEN region = 'East' THEN sales_amount ELSE 0 END) as East,
    SUM(CASE WHEN region = 'West' THEN sales_amount ELSE 0 END) as West,
    -- Statistical measures across regions
    ROUND(
        (SUM(CASE WHEN region = 'North' THEN sales_amount ELSE 0 END) +
         SUM(CASE WHEN region = 'South' THEN sales_amount ELSE 0 END) +
         SUM(CASE WHEN region = 'East' THEN sales_amount ELSE 0 END) +
         SUM(CASE WHEN region = 'West' THEN sales_amount ELSE 0 END)) / 4.0,
        2
    ) as Avg_Regional_Sales,
    -- Standard deviation approximation
    ROUND(
        SQRT(
            (POWER(SUM(CASE WHEN region = 'North' THEN sales_amount ELSE 0 END) - 
                   ((SUM(CASE WHEN region = 'North' THEN sales_amount ELSE 0 END) +
                     SUM(CASE WHEN region = 'South' THEN sales_amount ELSE 0 END) +
                     SUM(CASE WHEN region = 'East' THEN sales_amount ELSE 0 END) +
                     SUM(CASE WHEN region = 'West' THEN sales_amount ELSE 0 END)) / 4.0), 2) +
             -- Similar calculations for other regions would go here...
             0) / 4.0
        ), 2
    ) as Regional_Variation
FROM monthly_sales
GROUP BY product
ORDER BY product;

-- 11. Pivot table with totals and subtotals
SELECT 
    COALESCE(product, 'GRAND TOTAL') as product,
    SUM(CASE WHEN region = 'North' THEN sales_amount ELSE 0 END) as North,
    SUM(CASE WHEN region = 'South' THEN sales_amount ELSE 0 END) as South,
    SUM(CASE WHEN region = 'East' THEN sales_amount ELSE 0 END) as East,
    SUM(CASE WHEN region = 'West' THEN sales_amount ELSE 0 END) as West,
    SUM(sales_amount) as Total
FROM monthly_sales
GROUP BY ROLLUP(product)
ORDER BY 
    CASE WHEN product IS NULL THEN 1 ELSE 0 END,
    product;

-- Cleanup
DROP TABLE IF EXISTS pivoted_sales;
-- DROP TABLE IF EXISTS monthly_sales;

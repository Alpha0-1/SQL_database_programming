-- File: 1-ranking.sql
-- Description: ROW_NUMBER, RANK, and DENSE_RANK functions explained
-- Author: Alpha0-1
-- Date: 2025

-- Ranking functions assign ranks to rows based on specified criteria
-- Understanding the differences between ROW_NUMBER, RANK, and DENSE_RANK is crucial

-- Sample data for ranking demonstrations
CREATE TABLE IF NOT EXISTS sales_data (
    id INT PRIMARY KEY,
    salesperson VARCHAR(100),
    region VARCHAR(50),
    sales_amount DECIMAL(10,2),
    quarter VARCHAR(10)
);

INSERT INTO sales_data VALUES
(1, 'John Doe', 'North', 100000.00, 'Q1'),
(2, 'Jane Smith', 'North', 120000.00, 'Q1'),
(3, 'Mike Johnson', 'South', 90000.00, 'Q1'),
(4, 'Sarah Davis', 'South', 120000.00, 'Q1'),  -- Same as Jane
(5, 'Tom Wilson', 'East', 110000.00, 'Q1'),
(6, 'Lisa Brown', 'East', 95000.00, 'Q1'),
(7, 'Chris Lee', 'West', 120000.00, 'Q1'),    -- Same as Jane and Sarah
(8, 'Amy Taylor', 'West', 85000.00, 'Q1'),
(9, 'David Chen', 'North', 130000.00, 'Q2'),
(10, 'Emma Wilson', 'South', 115000.00, 'Q2');

-- 1. ROW_NUMBER() - Assigns unique sequential integers
-- Always returns unique values, even for ties
SELECT 
    salesperson,
    region,
    sales_amount,
    -- Unique row numbers ordered by sales amount (descending)
    ROW_NUMBER() OVER(ORDER BY sales_amount DESC) as row_num_overall,
    -- Unique row numbers within each region
    ROW_NUMBER() OVER(PARTITION BY region ORDER BY sales_amount DESC) as row_num_by_region
FROM sales_data
WHERE quarter = 'Q1'
ORDER BY sales_amount DESC;

-- 2. RANK() - Assigns ranks with gaps for ties
-- Same values get same rank, next rank skips numbers
SELECT 
    salesperson,
    region,
    sales_amount,
    -- Overall ranking with gaps for ties
    RANK() OVER(ORDER BY sales_amount DESC) as rank_overall,
    -- Regional ranking with gaps for ties
    RANK() OVER(PARTITION BY region ORDER BY sales_amount DESC) as rank_by_region
FROM sales_data
WHERE quarter = 'Q1'
ORDER BY sales_amount DESC;

-- 3. DENSE_RANK() - Assigns ranks without gaps for ties
-- Same values get same rank, next rank is consecutive
SELECT 
    salesperson,
    region,
    sales_amount,
    -- Overall dense ranking without gaps
    DENSE_RANK() OVER(ORDER BY sales_amount DESC) as dense_rank_overall,
    -- Regional dense ranking without gaps
    DENSE_RANK() OVER(PARTITION BY region ORDER BY sales_amount DESC) as dense_rank_by_region
FROM sales_data
WHERE quarter = 'Q1'
ORDER BY sales_amount DESC;

-- 4. Comparison of all three ranking functions
SELECT 
    salesperson,
    region,
    sales_amount,
    ROW_NUMBER() OVER(ORDER BY sales_amount DESC) as row_number,
    RANK() OVER(ORDER BY sales_amount DESC) as rank_func,
    DENSE_RANK() OVER(ORDER BY sales_amount DESC) as dense_rank,
    -- Show the differences
    CASE 
        WHEN RANK() OVER(ORDER BY sales_amount DESC) = 
             DENSE_RANK() OVER(ORDER BY sales_amount DESC) 
        THEN 'No ties above'
        ELSE 'Ties exist above'
    END as tie_indicator
FROM sales_data
WHERE quarter = 'Q1'
ORDER BY sales_amount DESC;

-- 5. Practical example: Top N per group
-- Find top 2 salespeople in each region
WITH ranked_sales AS (
    SELECT 
        salesperson,
        region,
        sales_amount,
        RANK() OVER(PARTITION BY region ORDER BY sales_amount DESC) as sales_rank
    FROM sales_data
    WHERE quarter = 'Q1'
)
SELECT 
    salesperson,
    region,
    sales_amount,
    sales_rank
FROM ranked_sales
WHERE sales_rank <= 2
ORDER BY region, sales_rank;

-- 6. Using DENSE_RANK for percentile calculations
SELECT 
    salesperson,
    region,
    sales_amount,
    DENSE_RANK() OVER(ORDER BY sales_amount DESC) as performance_tier,
    -- Calculate performance level based on dense rank
    CASE 
        WHEN DENSE_RANK() OVER(ORDER BY sales_amount DESC) = 1 
        THEN 'Top Performer'
        WHEN DENSE_RANK() OVER(ORDER BY sales_amount DESC) <= 3 
        THEN 'High Performer'
        WHEN DENSE_RANK() OVER(ORDER BY sales_amount DESC) <= 5 
        THEN 'Average Performer'
        ELSE 'Needs Improvement'
    END as performance_category
FROM sales_data
WHERE quarter = 'Q1'
ORDER BY sales_amount DESC;

-- 7. Advanced ranking with multiple criteria
SELECT 
    salesperson,
    region,
    sales_amount,
    -- Primary ranking by sales amount
    RANK() OVER(ORDER BY sales_amount DESC) as primary_rank,
    -- Secondary ranking by region, then sales
    RANK() OVER(PARTITION BY region ORDER BY sales_amount DESC) as regional_rank,
    -- Complex ranking: sales amount desc, then by name asc for ties
    RANK() OVER(ORDER BY sales_amount DESC, salesperson ASC) as tiebreaker_rank
FROM sales_data
WHERE quarter = 'Q1'
ORDER BY sales_amount DESC, salesperson;

-- 8. Ranking with NULL handling
-- Insert some NULL values for demonstration
INSERT INTO sales_data VALUES
(11, 'Test Person', 'North', NULL, 'Q1');

SELECT 
    salesperson,
    region,
    sales_amount,
    -- ROW_NUMBER treats NULLs based on ORDER BY
    ROW_NUMBER() OVER(ORDER BY sales_amount DESC NULLS LAST) as row_num,
    -- RANK with NULL handling
    RANK() OVER(ORDER BY sales_amount DESC NULLS LAST) as rank_nulls_last,
    -- Handle NULLs explicitly
    RANK() OVER(ORDER BY COALESCE(sales_amount, 0) DESC) as rank_nulls_as_zero
FROM sales_data
WHERE quarter = 'Q1'
ORDER BY sales_amount DESC NULLS LAST;

-- 9. Quarter-over-quarter ranking comparison
SELECT 
    salesperson,
    region,
    quarter,
    sales_amount,
    RANK() OVER(PARTITION BY quarter ORDER BY sales_amount DESC) as quarterly_rank,
    -- Show rank change (would need more data for meaningful comparison)
    LAG(RANK() OVER(PARTITION BY quarter ORDER BY sales_amount DESC)) 
        OVER(PARTITION BY salesperson ORDER BY quarter) as prev_quarter_rank
FROM sales_data
ORDER BY salesperson, quarter;

-- 10. Finding duplicates using ROW_NUMBER
-- Identify salespeople with same sales amounts
WITH duplicate_check AS (
    SELECT 
        salesperson,
        region,
        sales_amount,
        ROW_NUMBER() OVER(PARTITION BY sales_amount ORDER BY salesperson) as dup_check
    FROM sales_data
    WHERE quarter = 'Q1'
)
SELECT 
    salesperson,
    region,
    sales_amount,
    'Duplicate sales amount' as note
FROM duplicate_check
WHERE dup_check > 1
ORDER BY sales_amount DESC;

-- Cleanup
DELETE FROM sales_data WHERE salesperson = 'Test Person';
-- DROP TABLE IF EXISTS sales_data;

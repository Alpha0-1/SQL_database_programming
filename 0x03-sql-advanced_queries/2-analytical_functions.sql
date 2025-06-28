-- File: 2-analytical_functions.sql
-- Description: LAG, LEAD, FIRST_VALUE, LAST_VALUE analytical functions
-- Author: Alpha0-1
-- Date: 2025

-- Analytical functions help analyze data by comparing current row with other rows
-- These functions are essential for time-series analysis and trend identification

-- Sample data: Stock prices over time
CREATE TABLE IF NOT EXISTS stock_prices (
    id INT PRIMARY KEY,
    stock_symbol VARCHAR(10),
    trade_date DATE,
    opening_price DECIMAL(10,2),
    closing_price DECIMAL(10,2),
    volume INT
);

INSERT INTO stock_prices VALUES
(1, 'AAPL', '2024-01-01', 150.00, 152.00, 1000000),
(2, 'AAPL', '2024-01-02', 152.00, 148.00, 1200000),
(3, 'AAPL', '2024-01-03', 148.00, 155.00, 900000),
(4, 'AAPL', '2024-01-04', 155.00, 153.00, 1100000),
(5, 'AAPL', '2024-01-05', 153.00, 157.00, 800000),
(6, 'GOOGL', '2024-01-01', 2800.00, 2820.00, 500000),
(7, 'GOOGL', '2024-01-02', 2820.00, 2790.00, 600000),
(8, 'GOOGL', '2024-01-03', 2790.00, 2850.00, 450000),
(9, 'GOOGL', '2024-01-04', 2850.00, 2830.00, 550000),
(10, 'GOOGL', '2024-01-05', 2830.00, 2870.00, 400000);

-- 1. LAG() function - Access previous row values
-- Syntax: LAG(column, offset, default_value) OVER(ORDER BY ...)
SELECT 
    stock_symbol,
    trade_date,
    closing_price,
    -- Previous day's closing price
    LAG(closing_price) OVER(
        PARTITION BY stock_symbol 
        ORDER BY trade_date
    ) as prev_closing_price,
    -- Price change from previous day
    closing_price - LAG(closing_price) OVER(
        PARTITION BY stock_symbol 
        ORDER BY trade_date
    ) as daily_change,
    -- Previous day's volume
    LAG(volume, 1, 0) OVER(
        PARTITION BY stock_symbol 
        ORDER BY trade_date
    ) as prev_volume
FROM stock_prices
ORDER BY stock_symbol, trade_date;

-- 2. LEAD() function - Access next row values
-- Syntax: LEAD(column, offset, default_value) OVER(ORDER BY ...)
SELECT 
    stock_symbol,
    trade_date,
    closing_price,
    -- Next day's closing price
    LEAD(closing_price) OVER(
        PARTITION BY stock_symbol 
        ORDER BY trade_date
    ) as next_closing_price,
    -- Will price go up tomorrow?
    CASE 
        WHEN LEAD(closing_price) OVER(
            PARTITION BY stock_symbol 
            ORDER BY trade_date
        ) > closing_price THEN 'UP'
        WHEN LEAD(closing_price) OVER(
            PARTITION BY stock_symbol 
            ORDER BY trade_date
        ) < closing_price THEN 'DOWN'
        ELSE 'SAME'
    END as next_day_direction,
    -- Look ahead 2 days
    LEAD(closing_price, 2) OVER(
        PARTITION BY stock_symbol 
        ORDER BY trade_date
    ) as price_in_2_days
FROM stock_prices
ORDER BY stock_symbol, trade_date;

-- 3. FIRST_VALUE() function - First value in window frame
SELECT 
    stock_symbol,
    trade_date,
    closing_price,
    -- First closing price in the dataset for each stock
    FIRST_VALUE(closing_price) OVER(
        PARTITION BY stock_symbol 
        ORDER BY trade_date
        ROWS UNBOUNDED PRECEDING
    ) as first_price,
    -- Performance since first day
    ((closing_price - FIRST_VALUE(closing_price) OVER(
        PARTITION BY stock_symbol 
        ORDER BY trade_date
        ROWS UNBOUNDED PRECEDING
    )) / FIRST_VALUE(closing_price) OVER(
        PARTITION BY stock_symbol 
        ORDER BY trade_date
        ROWS UNBOUNDED PRECEDING
    )) * 100 as percent_change_from_start,
    -- First trade date for reference
    FIRST_VALUE(trade_date) OVER(
        PARTITION BY stock_symbol 
        ORDER BY trade_date
        ROWS UNBOUNDED PRECEDING
    ) as first_trade_date
FROM stock_prices
ORDER BY stock_symbol, trade_date;

-- 4. LAST_VALUE() function - Last value in window frame
-- Note: Need to specify frame properly for LAST_VALUE to work as expected
SELECT 
    stock_symbol,
    trade_date,
    closing_price,
    -- Last closing price in the complete dataset for each stock
    LAST_VALUE(closing_price) OVER(
        PARTITION BY stock_symbol 
        ORDER BY trade_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) as final_price,
    -- Performance to final day
    ((LAST_VALUE(closing_price) OVER(
        PARTITION BY stock_symbol 
        ORDER BY trade_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) - closing_price) / closing_price) * 100 as percent_to_final,
    -- Last trade date for reference
    LAST_VALUE(trade_date) OVER(
        PARTITION BY stock_symbol 
        ORDER BY trade_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) as final_trade_date
FROM stock_prices
ORDER BY stock_symbol, trade_date;

-- 5. Combining multiple analytical functions for trend analysis
SELECT 
    stock_symbol,
    trade_date,
    closing_price,
    -- Previous and next prices
    LAG(closing_price) OVER(
        PARTITION BY stock_symbol ORDER BY trade_date
    ) as prev_price,
    LEAD(closing_price) OVER(
        PARTITION BY stock_symbol ORDER BY trade_date
    ) as next_price,
    -- Trend identification
    CASE 
        WHEN LAG(closing_price) OVER(PARTITION BY stock_symbol ORDER BY trade_date) < closing_price
             AND closing_price < LEAD(closing_price) OVER(PARTITION BY stock_symbol ORDER BY trade_date)
        THEN 'Upward Trend'
        WHEN LAG(closing_price) OVER(PARTITION BY stock_symbol ORDER BY trade_date) > closing_price
             AND closing_price > LEAD(closing_price) OVER(PARTITION BY stock_symbol ORDER BY trade_date)
        THEN 'Downward Trend'
        ELSE 'Mixed/Unclear'
    END as trend_direction
FROM stock_prices
ORDER BY stock_symbol, trade_date;

-- 6. Moving averages using analytical functions
SELECT 
    stock_symbol,
    trade_date,
    closing_price,
    -- 3-day moving average (current + 2 previous)
    AVG(closing_price) OVER(
        PARTITION BY stock_symbol 
        ORDER BY trade_date
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) as ma_3_day,
    -- Compare current price to moving average
    CASE 
        WHEN closing_price > AVG(closing_price) OVER(
            PARTITION BY stock_symbol 
            ORDER BY trade_date
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) THEN 'Above MA'
        ELSE 'Below MA'
    END as vs_moving_avg
FROM stock_prices
ORDER BY stock_symbol, trade_date;

-- 7. Gap analysis using LAG and LEAD
SELECT 
    stock_symbol,
    trade_date,
    opening_price,
    closing_price,
    LAG(closing_price) OVER(
        PARTITION BY stock_symbol ORDER BY trade_date
    ) as prev_closing,
    -- Gap up/down analysis
    opening_price - LAG(closing_price) OVER(
        PARTITION BY stock_symbol ORDER BY trade_date
    ) as gap_amount,
    CASE 
        WHEN opening_price > LAG(closing_price) OVER(
            PARTITION BY stock_symbol ORDER BY trade_date
        ) THEN 'Gap Up'
        WHEN opening_price < LAG(closing_price) OVER(
            PARTITION BY stock_symbol ORDER BY trade_date
        ) THEN 'Gap Down'
        ELSE 'No Gap'
    END as gap_type
FROM stock_prices
ORDER BY stock_symbol, trade_date;

-- 8. Advanced example: Support and Resistance levels
WITH price_analysis AS (
    SELECT 
        stock_symbol,
        trade_date,
        closing_price,
        -- Highest price in last 3 days (resistance)
        MAX(closing_price) OVER(
            PARTITION BY stock_symbol 
            ORDER BY trade_date
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) as resistance_level,
        -- Lowest price in last 3 days (support)
        MIN(closing_price) OVER(
            PARTITION BY stock_symbol 
            ORDER BY trade_date
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) as support_level
    FROM stock_prices
)
SELECT 
    stock_symbol,
    trade_date,
    closing_price,
    resistance_level,
    support_level,
    -- Position within support-resistance range
    CASE 
        WHEN closing_price = resistance_level THEN 'At Resistance'
        WHEN closing_price = support_level THEN 'At Support'
        WHEN closing_price > (support_level + resistance_level) / 2 THEN 'Upper Half'
        ELSE 'Lower Half'
    END as position_in_range
FROM price_analysis
ORDER BY stock_symbol, trade_date;

-- 9. Time-based comparisons with specific offsets
SELECT 
    stock_symbol,
    trade_date,
    closing_price,
    -- Compare with 2 days ago
    LAG(closing_price, 2) OVER(
        PARTITION BY stock_symbol ORDER BY trade_date
    ) as price_2_days_ago,
    -- 2-day change
    closing_price - LAG(closing_price, 2) OVER(
        PARTITION BY stock_symbol ORDER BY trade_date
    ) as change_2_days,
    -- Weekly comparison (would need more data)
    LAG(closing_price, 5, closing_price) OVER(
        PARTITION BY stock_symbol ORDER BY trade_date
    ) as price_week_ago
FROM stock_prices
ORDER BY stock_symbol, trade_date;

-- 10. Practical example: Identifying turning points
SELECT 
    stock_symbol,
    trade_date,
    closing_price,
    LAG(closing_price) OVER(PARTITION BY stock_symbol ORDER BY trade_date) as prev_price,
    LEAD(closing_price) OVER(PARTITION BY stock_symbol ORDER BY trade_date) as next_price,
    -- Identify peaks and valleys
    CASE 
        WHEN closing_price > COALESCE(LAG(closing_price) OVER(PARTITION BY stock_symbol ORDER BY trade_date), 0)
             AND closing_price > COALESCE(LEAD(closing_price) OVER(PARTITION BY stock_symbol ORDER BY trade_date), 0)
        THEN 'Local Peak'
        WHEN closing_price < COALESCE(LAG(closing_price) OVER(PARTITION BY stock_symbol ORDER BY trade_date), 999999)
             AND closing_price < COALESCE(LEAD(closing_price) OVER(PARTITION BY stock_symbol ORDER BY trade_date), 999999)
        THEN 'Local Valley'
        ELSE 'Normal'
    END as turning_point
FROM stock_prices
ORDER BY stock_symbol, trade_date;

-- Cleanup (optional)
-- DROP TABLE IF EXISTS stock_prices;

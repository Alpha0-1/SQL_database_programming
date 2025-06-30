/*
 * File: 9-comparative_analysis.sql
 * Description: Perform period-over-period analysis
 * 
 * This script provides SQL queries to compare performance
 * over different time periods:
 * - Monthly Comparison
 * - Quarterly Comparison
 * - Year-Over-Year (YoY) Comparison
 */

/*
 * Configuration Section
 * 
 * Modify these values to match your database schema
 */
USE business_intelligence_db;

/*
 * Monthly Sales Comparison
 * 
 * Compares sales performance month-over-month
 */
WITH 
  monthly_sales AS (
    SELECT 
        DATE_TRUNC('month', order_date) AS month,
        SUM(order_amount) AS total_sales
    FROM 
        orders
    WHERE 
        order_date BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY 
        month
  )
SELECT 
    month,
    total_sales,
    LAG(total_sales, 1) OVER (ORDER BY month) AS previous_month_sales,
    ROUND(
        (total_sales - LAG(total_sales, 1) OVER (ORDER BY month)) / LAG(total_sales, 1) OVER (ORDER BY month) * 100
        , 2
    ) AS month_over_month_growth
FROM 
    monthly_sales
ORDER BY 
    month ASC;

/*
 * Quarterly Financial Comparison
 * 
 * Compares financial performance quarter-over-quarter
 */
WITH 
  quarterly_results AS (
    SELECT 
        DATE_TRUNC('quarter', reporting_date) AS quarter,
        SUM(revenue) AS total_revenue,
        SUM(expenses) AS total_expenses,
        SUM(profit) AS total_profit
    FROM 
        financial_results
    WHERE 
        reporting_date BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY 
        quarter
  )
SELECT 
    quarter,
    total_revenue,
    total_expenses,
    total_profit,
    LAG(total_revenue, 1) OVER (ORDER BY quarter) AS previous_quarter_revenue,
    LAG(total_expenses, 1) OVER (ORDER BY quarter) AS previous_quarter_expenses,
    LAG(total_profit, 1) OVER (ORDER BY quarter) AS previous_quarter_profit,
    ROUND(
        (total_revenue - LAG(total_revenue, 1) OVER (ORDER BY quarter)) / LAG(total_revenue, 1) OVER (ORDER BY quarter) * 100
        , 2
    ) AS quarter_over_quarter_growth
FROM 
    quarterly_results
ORDER BY 
    quarter ASC;

/*
 * Year-Over-Year (YoY) Sales Comparison
 * 
 * Compares sales performance year-over-year
 */
WITH 
  yearly_sales AS (
    SELECT 
        EXTRACT(YEAR FROM order_date) AS year,
        SUM(order_amount) AS total_sales
    FROM 
        orders
    WHERE 
        order_date BETWEEN '2022-01-01' AND '2023-12-31'
    GROUP BY 
        year
  )
SELECT 
    year,
    total_sales,
    LAG(total_sales, 1) OVER (ORDER BY year) AS previous_year_sales,
    ROUND(
        (total_sales - LAG(total_sales, 1) OVER (ORDER BY year)) / LAG(total_sales, 1) OVER (ORDER BY year) * 100
        , 2
    ) AS yoy_growth
FROM 
    yearly_sales
ORDER BY 
    year ASC;

/*
 * Usage Notes:
 * 1. Replace the date ranges with appropriate values for your analysis
 * 2. Adjust column names and table names to match your database schema
 * 3. Add additional comparative metrics as needed for your organization
 *
 * Common Extensions:
 * - Add day-over-day comparisons
 * - Include seasonal adjustments
 * - Add market comparison metrics
 */

/*
 * File: 10-variance_analysis.sql
 * Description: Perform variance analysis
 * 
 * This script provides SQL queries to analyze variances between:
 * - Budget vs Actual
 * - Forecast vs Actual
 * - Previous Period vs Current Period
 */

/*
 * Configuration Section
 * 
 * Modify these values to match your database schema
 */
USE business_intelligence_db;

/*
 * Budget vs Actual Analysis
 * 
 * Compares budgeted figures to actual results
 */
SELECT 
    expense_category,
    budgeted_amount,
    actual_amount,
    ROUND(
        (actual_amount - budgeted_amount) / budgeted_amount * 100
        , 2
    ) AS variance_percentage,
    CASE
        WHEN actual_amount > budgeted_amount THEN 'Over Budget'
        ELSE 'Under Budget'
    END AS variance_status
FROM 
    budget_comparison
WHERE 
    reporting_date BETWEEN '2023-01-01' AND '2023-12-31'
ORDER BY 
    variance_percentage DESC;

/*
 * Forecast vs Actual Analysis
 * 
 * Compares forecasted figures to actual results
 */
SELECT 
    metric_name,
    forecast_value,
    actual_value,
    ROUND(
        (actual_value - forecast_value) / forecast_value * 100
        , 2
    ) AS variance_percentage,
    CASE
        WHEN actual_value > forecast_value THEN 'Above Forecast'
        ELSE 'Below Forecast'
    END AS variance_status
FROM 
    forecast_comparison
WHERE 
    reporting_date BETWEEN '2023-01-01' AND '2023-12-31'
ORDER BY 
    variance_percentage DESC;

/*
 * Previous Period vs Current Period Analysis
 * 
 * Compares performance to previous time period
 */
WITH 
  period_data AS (
    SELECT 
        period,
        metric_value
    FROM 
        period_comparison
    WHERE 
        reporting_date BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY 
        period, metric_value
  )
SELECT 
    current.period AS current_period,
    previous.metric_value AS previous_period_value,
    current.metric_value AS current_period_value,
    ROUND(
        (current.metric_value - previous.metric_value) / previous.metric_value * 100
        , 2
    ) AS period_over_period_variance
FROM 
    period_data current
LEFT JOIN 
    period_data previous ON current.period = DATEADD(MONTH, 1, previous.period)
WHERE 
    current.period > (SELECT MIN(period) FROM period_data)
ORDER BY 
    current.period ASC;

/*
 * Usage Notes:
 * 1. Replace the date ranges with appropriate values for your analysis
 * 2. Adjust column names and table names to match your database schema
 * 3. Add additional variance metrics as needed for your organization
 *
 * Common Extensions:
 * - Add multi-variate analysis
 * - Include trend analysis
 * - Add driver analysis for variance
 */

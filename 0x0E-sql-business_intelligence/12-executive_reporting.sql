/*
 * File: 12-executive_reporting.sql
 * Description: Generate executive dashboards
 * 
 * This script provides SQL queries to generate executive-level reports.
 */

/*
 * Configuration Section
 * 
 * Modify these values to match your database schema
 */
USE business_intelligence_db;

/*
 * Executive Dashboard - Key Metrics
 */
SELECT 
    'Executive Dashboard' AS report_name,
    SUM(order_amount) AS total_revenue,
    COUNT(DISTINCT(order_id)) AS total_orders,
    COUNT(DISTINCT(customer_id)) AS total_customers,
    ROUND(AVG(order_amount), 2) AS average_order_value,
    ROUND(
        (SUM(profit) / SUM(revenue)) * 100
        , 2
    ) AS profit_margin
FROM 
    orders
LEFT JOIN 
    financial_results ON orders.order_date = financial_results.reporting_date
WHERE 
    order_date BETWEEN '2023-01-01' AND '2023-12-31';

/*
 * Executive Dashboard - Financial Summary
 */
SELECT 
    'Financial Summary' AS metric_type,
    SUM(revenue) AS total_revenue,
    SUM(expenses) AS total_expenses,
    SUM(profit) AS net_profit,
    ROUND(AVG(gross_margin), 2) AS average_gross_margin
FROM 
    financial_results
WHERE 
    reporting_date BETWEEN '2023-01-01' AND '2023-12-31';

/*
 * Executive Dashboard - Operational Efficiency
 */
SELECT 
    'Operational Efficiency' AS metric_type,
    COUNT(order_id) AS total_orders,
    ROUND(AVG(delivery_time), 2) AS average_handling_time,
    ROUND(
        (COUNT(CASE WHEN delivery_status = 'delivered' THEN order_id END) / COUNT(order_id)) * 100
        , 2
    ) AS order_accuracy
FROM 
    order_fulfillment
WHERE 
    order_date BETWEEN '2023-01-01' AND '2023-12-31';

/*
 * Executive Dashboard - Growth Metrics
 */
SELECT 
    'Growth Metrics' AS metric_type,
    ROUND(
        ((SUM(order_amount) - LAG(SUM(order_amount), 1) OVER (ORDER BY reporting_date)) / LAG(SUM(order_amount), 1) OVER (ORDER BY reporting_date)) * 100
        , 2
    ) AS year_over_year_growth,
    ROUND(
        ((SUM(order_amount) - LAG(SUM(order_amount), 3) OVER (ORDER BY reporting_date)) / LAG(SUM(order_amount), 3) OVER (ORDER BY reporting_date)) * 100
        , 2
    ) AS quarter_over_quarter_growth
FROM 
    financial_results
WHERE 
    reporting_date BETWEEN '2022-01-01' AND '2023-12-31'
GROUP BY 
    reporting_date
ORDER BY 
    reporting_date ASC;

/*
 * Usage Notes:
 * 1. Replace the date ranges with appropriate values for your analysis
 * 2. Adjust column names and table names to match your database schema
 * 3. Add additional executive metrics as needed for your organization
 *
 * Common Extensions:
 * - Add customer retention metrics
 * - Include market share analysis
 * - Add competitive benchmarking
 */

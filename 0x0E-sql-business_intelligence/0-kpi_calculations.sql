/*
 * File: 0-kpi_calculations.sql
 * Description: Calculate Key Performance Indicators (KPIs)
 * 
 * This script demonstrates how to calculate common KPIs 
 * that are essential for business intelligence analysis.
 *
 * KPIs covered:
 * - Revenue
 * - Average Order Value
 * - Conversion Rate
 * - Customer Retention Rate
 * - Gross Margin
 */

/*
 * Configuration Section
 * 
 * Modify these values to match your database schema
 */
USE business_intelligence_db;

/*
 * Revenue Calculation
 * 
 * Measures total sales for a given period
 */
SELECT 
    SUM(order_amount) AS total_revenue
FROM 
    orders
WHERE 
    order_date BETWEEN '2023-01-01' AND '2023-12-31';

/*
 * Average Order Value (AOV)
 * 
 * Indicates average spending per order
 */
SELECT 
    AVG(order_amount) AS average_order_value
FROM 
    orders
WHERE 
    order_date BETWEEN '2023-01-01' AND '2023-12-31';

/*
 * Conversion Rate
 * 
 * Calculates percentage of visitors who make a purchase
 */
SELECT 
    (COUNT(DISTINCT(order_id)) / COUNT(DISTINCT(visitor_id))) * 100 AS conversion_rate
FROM 
    order_tracking
WHERE 
    tracking_date BETWEEN '2023-01-01' AND '2023-12-31';

/*
 * Customer Retention Rate
 * 
 * Measures percentage of customers who return to make another purchase
 */
WITH 
  first_order AS (
    SELECT 
        customer_id,
        MIN(order_date) AS first_order_date
    FROM 
        orders
    GROUP BY 
        customer_id
  ),
  second_order AS (
    SELECT 
        customer_id,
        MIN(order_date) AS second_order_date
    FROM 
        orders
    WHERE 
        order_date > (SELECT first_order_date FROM first_order LIMIT 1)
    GROUP BY 
        customer_id
  )
SELECT 
    COUNT(oru.customer_id) / COUNT(fru.customer_id) * 100 AS retention_rate
FROM 
    first_order fru
LEFT JOIN 
    second_order oru ON fru.customer_id = oru.customer_id
WHERE 
    fru.first_order_date BETWEEN '2023-01-01' AND '2023-12-31';

/*
 * Gross Margin
 * 
 * Indicates profitability after deducting cost of goods sold
 */
SELECT 
    SUM((order_amount - cost_of_goods) / order_amount * 100) AS gross_margin_percentage
FROM 
    orders
WHERE 
    order_date BETWEEN '2023-01-01' AND '2023-12-31';

/*
 * Usage Notes:
 * 1. Replace the date ranges with appropriate values for your analysis
 * 2. Adjust column names and table names to match your database schema
 * 3. Add additional KPIs as needed for your organization
 *
 * Common Extensions:
 * - Add by-time-period breakdowns (daily, weekly, monthly)
 * - Include comparison to previous periods
 * - Add dimension analysis (e.g., by product, region, etc.)
 */

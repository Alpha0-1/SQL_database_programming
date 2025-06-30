/*
 * File: 102-self_service_bi.sql
 * Description: Enable self-service BI
 * 
 * This script provides examples of how to create
 * self-service BI queries and reports.
 */

/*
 * Configuration Section
 * 
 * Modify these values to match your database schema
 */
USE business_intelligence_db;

/*
 * Simple Sales Report
 * 
 * Example of a basic report
 */
WITH 
  sales_data AS (
    SELECT 
        DATE_TRUNC('month', order_date) AS month,
        product_id,
        COUNT(order_id) AS units_sold,
        SUM(order_amount) AS sales
    FROM 
        orders
    WHERE 
        order_date BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY 
        month, product_id
  )
SELECT 
    month,
    product_id,
    units_sold,
    sales,
    ROUND(
        (sales / (SELECT SUM(sales) FROM sales_data)) * 100
        , 2
    ) AS sales_contribution
FROM 
    sales_data
ORDER BY 
    month ASC, product_id ASC;

/*
 * Interactive Dashboard Query
 * 
 * Example of a query that can be used in a dashboard
 */
SELECT 
    region,
    DATE_TRUNC('week', order_date) AS week,
    COUNT(order_id) AS total_orders,
    SUM(order_amount) AS total_sales
FROM 
    orders
LEFT JOIN 
    customers ON orders.customer_id = customers.customer_id
WHERE 
    order_date BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    region, week
ORDER BY 
    region, week ASC;

/*
 * Drill-Through Query
 * 
 * Example of a query that provides detailed data
 */
SELECT 
    order_id,
    order_date,
    customer_id,
    product_id,
    order_amount
FROM 
    orders
WHERE 
    order_date BETWEEN '2023-01-01' AND '2023-12-31'
AND 
    order_amount >= (
        SELECT 
            PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY order_amount)
        FROM 
            orders
    )
ORDER BY 
    order_date DESC;

/*
 * Usage Notes:
 * 1. Replace the date ranges with appropriate values for your analysis
 * 2. Adjust column names and table names to match your database schema
 * 3. Add additional self-service features as needed for your organization
 *
 * Common Extensions:
 * - Add filtering options
 * - Include sorting and pagination
 * - Add calculations (e.g., YTD, MTD)
 */

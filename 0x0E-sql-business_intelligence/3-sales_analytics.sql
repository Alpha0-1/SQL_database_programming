/*
 * File: 3-sales_analytics.sql
 * Description: Perform sales analysis
 * 
 * This script provides SQL queries to analyze sales data:
 * - Sales by Product
 * - Sales by Channel
 * - Sales Trends
 * - Customer Lifetime Value (CLV)
 */

/*
 * Configuration Section
 * 
 * Modify these values to match your database schema
 */
USE business_intelligence_db;

/*
 * Sales by Product
 * 
 * Breaks down sales performance by product
 */
SELECT 
    product_id,
    SUM(order_amount) AS total_sales,
    COUNT(DISTINCT(order_id)) AS total_units_sold,
    ROUND(AVG(order_amount), 2) AS average_sale_price
FROM 
    order_items
WHERE 
    order_date BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    product_id
ORDER BY 
    total_sales DESC;

/*
 * Sales by Channel
 * 
 * Breaks down sales performance by sales channel
 */
SELECT 
    channel,
    SUM(order_amount) AS total_sales,
    COUNT(DISTINCT(order_id)) AS total_orders,
    ROUND(AVG(order_amount), 2) AS average_order_value
FROM 
    orders
WHERE 
    order_date BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    channel
ORDER BY 
    total_sales DESC;

/*
 * Sales Trends
 * 
 * Provides time-series analysis of sales performance
 */
SELECT 
    DATE_TRUNC('month', order_date) AS month,
    SUM(order_amount) AS total_sales,
    COUNT(DISTINCT(order_id)) AS total_orders,
    ROUND(AVG(order_amount), 2) AS average_order_value
FROM 
    orders
WHERE 
    order_date BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    month
ORDER BY 
    month ASC;

/*
 * Customer Lifetime Value (CLV)
 * 
 * Calculates the average lifetime value of customers
 */
WITH 
  customer_sales AS (
    SELECT 
        customer_id,
        SUM(order_amount) AS total_customer_value,
        COUNT(DISTINCT(order_id)) AS total_orders
    FROM 
        orders
    WHERE 
        order_date BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY 
        customer_id
  )
SELECT 
    ROUND(AVG(total_customer_value), 2) AS average_clv,
    ROUND(AVG(total_orders), 0) AS average_orders_per_customer
FROM 
    customer_sales;

/*
 * Usage Notes:
 * 1. Replace the date ranges with appropriate values for your analysis
 * 2. Adjust column names and table names to match your database schema
 * 3. Add additional sales metrics as needed for your organization
 *
 * Common Extensions:
 * - Add product category analysis
 * - Include customer segmentation
 * - Add promotional analysis
 */

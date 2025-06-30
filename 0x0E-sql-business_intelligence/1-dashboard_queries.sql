/*
 * File: 1-dashboard_queries.sql
 * Description: Create dashboard data queries
 * 
 * This script provides SQL queries to generate data
 * for business dashboards, including:
 * - Sales Overview
 * - Customer Metrics
 * - Top Products
 * - Performance by Region
 */

/*
 * Configuration Section
 * 
 * Modify these values to match your database schema
 */
USE business_intelligence_db;

/*
 * Sales Overview Dashboard
 * 
 * Provides summary metrics for sales performance
 */
SELECT 
    'Sales Overview' AS metric_type,
    SUM(order_amount) AS total_sales,
    COUNT(DISTINCT(order_id)) AS total_orders,
    COUNT(DISTINCT(customer_id)) AS total_customers,
    ROUND(AVG(order_amount), 2) AS average_order_value
FROM 
    orders
WHERE 
    order_date BETWEEN '2023-01-01' AND '2023-12-31';

/*
 * Customer Metrics Dashboard
 * 
 * Provides summary metrics for customer performance
 */
SELECT 
    'Customer Metrics' AS metric_type,
    COUNT(DISTINCT(customer_id)) AS total_customer_count,
    COUNT(DISTINCT(customer_id)) / COUNT(DISTINCT(visitor_id)) * 100 AS conversion_rate,
    ROUND(AVG(order_amount), 2) AS customer_lifetime_value
FROM 
    orders
LEFT JOIN 
    visitors ON orders.customer_id = visitors.customer_id
WHERE 
    order_date BETWEEN '2023-01-01' AND '2023-12-31';

/*
 * Top Products Dashboard
 * 
 * Shows top-performing products
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
    total_sales DESC
LIMIT 10;

/*
 * Performance by Region Dashboard
 * 
 * Breaks down performance by geographic region
 */
SELECT 
    region,
    SUM(order_amount) AS total_sales,
    COUNT(DISTINCT(customer_id)) AS customer_count,
    ROUND(AVG(order_amount), 2) AS average_order_value
FROM 
    orders
LEFT JOIN 
    customers ON orders.customer_id = customers.customer_id
WHERE 
    order_date BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    region
ORDER BY 
    total_sales DESC;

/*
 * Usage Notes:
 * 1. Replace the date ranges with appropriate values for your analysis
 * 2. Adjust column names and table names to match your database schema
 * 3. Add additional metrics as needed for your dashboards
 *
 * Common Extensions:
 * - Add time-series breakdowns (daily, weekly, monthly)
 * - Include comparison metrics (YoY, MoM)
 * - Add dimension filters (e.g., by product category, region, etc.)
 */

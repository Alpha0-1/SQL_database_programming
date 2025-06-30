/*
 * File: 100-real_time_analytics.sql
 * Description: Perform real-time analytics
 * 
 * This script provides SQL queries for real-time data analysis.
 */

/*
 * Configuration Section
 * 
 * Modify these values to match your database schema
 */
USE business_intelligence_db;

/*
 * Real-Time Sales Tracker
 * 
 * Provides up-to-the-minute sales metrics
 */
SELECT 
    'Real-Time Sales' AS metric_type,
    SUM(order_amount) AS current_sales,
    COUNT(DISTINCT(order_id)) AS total_orders,
    ROUND(AVG(order_amount), 2) AS average_order_value
FROM 
    orders
WHERE 
    order_date >= CURRENT_DATE - INTERVAL '5 minute';

/*
 * Real-Time Inventory Checker
 * 
 * Provides current stock levels
 */
SELECT 
    product_id,
    ROUND(AVG(stock_quantity), 2) AS average_stock,
    MAX(stock_quantity) AS max_stock,
    MIN(stock_quantity) AS min_stock
FROM 
    inventory
GROUP BY 
    product_id
HAVING 
    MAX(stock_quantity) < 100;

/*
 * Real-Time Customer Activity
 * 
 * Tracks recent customer actions
 */
SELECT 
    customer_id,
    COUNT(DISTINCT(order_id)) AS recent_orders,
    SUM(order_amount) AS total_spent,
    ROUND(AVG(order_amount), 2) AS average_order_value
FROM 
    orders
WHERE 
    order_date >= CURRENT_DATE - INTERVAL '24 hour'
GROUP BY 
    customer_id
HAVING 
    COUNT(DISTINCT(order_id)) > 0;

/*
 * Usage Notes:
 * 1. Ensure your database supports real-time or near-real-time querying
 * 2. Adjust time intervals as needed for your use case
 * 3. Add additional real-time metrics as needed for your organization
 *
 * Common Extensions:
 * - Add order processing status
 * - Include customer segmentation
 * - Add inventory alerts
 */

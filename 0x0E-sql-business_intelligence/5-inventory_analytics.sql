/*
 * File: 5-inventory_analytics.sql
 * Description: Perform inventory analysis
 * 
 * This script provides SQL queries to analyze inventory data:
 * - Stock Levels
 * - Inventory Turnover
 * - Excess Inventory
 * -(Item Out-of-Stock Analysis)
 */

/*
 * Configuration Section
 * 
 * Modify these values to match your database schema
 */
USE business_intelligence_db;

/*
 * Stock Levels
 * 
 * Provides current stock levels by product
 */
SELECT 
    product_id,
    SUM(stock_quantity) AS total_stock,
    SUM(stock_quantity) / (SELECT COUNT(DISTINCT(warehouse_id)) FROM warehouses) AS average_stock_per_warehouse
FROM 
    inventory
GROUP BY 
    product_id
ORDER BY 
    total_stock DESC;

/*
 * Inventory Turnover
 * 
 * Calculates inventory turnover ratio
 */
SELECT 
    ROUND(
        (SUM(order_amount) / (SUM(order_amount) / 365)) 
        / SUM(stock_value)
        , 2
    ) AS inventory_turnover_ratio
FROM 
    inventory
LEFT JOIN 
    orders ON inventory.product_id = orders.product_id
WHERE 
    order_date BETWEEN '2023-01-01' AND '2023-12-31';

/*
 * Excess Inventory
 * 
 * Identifies products with excess stock levels
 */
SELECT 
    product_id,
    SUM(stock_quantity) AS total_stock,
    CASE
        WHEN SUM(stock_quantity) > 1000 THEN 'High'
        WHEN SUM(stock_quantity) BETWEEN 500 AND 1000 THEN 'Moderate'
        ELSE 'Low'
    END AS stock_level
FROM 
    inventory
GROUP BY 
    product_id
HAVING 
   (sum(stock_quantity)) > 500
ORDER BY 
    total_stock DESC;

/*
 * Out-of-Stock Analysis
 * 
 * Identifies out-of-stock products
 */
SELECT 
    product_id,
    COUNT(DISTINCT(order_id)) AS total_orders,
    SUM(order_amount) AS total_sales
FROM 
    orders
WHERE 
    order_date BETWEEN '2023-01-01' AND '2023-12-31'
    AND product_id IN (
        SELECT 
            product_id 
        FROM 
            inventory 
        WHERE 
            stock_quantity = 0
    )
GROUP BY 
    product_id
ORDER BY 
    total_orders DESC;

/*
 * Usage Notes:
 * 1. Replace the date ranges with appropriate values for your analysis
 * 2. Adjust column names and table names to match your database schema
 * 3. Add additional inventory metrics as needed for your organization
 *
 * Common Extensions:
 * - Add product category analysis
 * - Include supplier performance
 * - Add reorder point alerts
 */

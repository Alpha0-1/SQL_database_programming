/*
 * File: 4-customer_analytics.sql
 * Description: Perform customer analysis
 * 
 * This script provides SQL queries to analyze customer data:
 * - Customer Segmentation
 * -Churn Analysis
 * - Customer Acquisition
 * -Customer Retention
 */

/*
 * Configuration Section
 * 
 * Modify these values to match your database schema
 */
USE business_intelligence_db;

/*
 * Customer Segmentation
 * 
 * Segments customers based on spending behavior
 */
SELECT 
    CASE
        WHEN total_purchases > 1000 THEN 'High-Value'
        WHEN total_purchases BETWEEN 500 AND 1000 THEN 'Medium-Value'
        ELSE 'Low-Value'
    END AS customer_segment,
    COUNT(DISTINCT(customer_id)) AS customer_count,
    SUM(total_spend) AS total_segment_value
FROM 
    (
        SELECT 
            customer_id,
            COUNT(order_id) AS total_purchases,
            SUM(order_amount) AS total_spend
        FROM 
            orders
        WHERE 
            order_date BETWEEN '2023-01-01' AND '2023-12-31'
        GROUP BY 
            customer_id
    ) AS customer_purchases
GROUP BY 
    customer_segment
ORDER BY 
    total_segment_value DESC;

/*
 * Customer Churn Analysis
 * 
 * Identifies customers who have stopped purchasing
 */
WITH 
  last_order AS (
    SELECT 
        customer_id,
        MAX(order_date) AS last_purchase_date
    FROM 
        orders
    GROUP BY 
        customer_id
  )
SELECT 
    COUNT(DISTINCT(customer_id)) / (
        SELECT COUNT(DISTINCT(customer_id)) 
        FROM orders 
        WHERE order_date >= '2023-01-01'
    ) * 100 AS churn_rate
FROM 
    last_order
WHERE 
    last_purchase_date < '2023-06-01';

/*
 * Customer Acquisition
 * 
 * Provides metrics on new customers
 */
SELECT 
    DATE_TRUNC('month', first_order_date) AS acquisition_month,
    COUNT(DISTINCT(customer_id)) AS new_customers,
    ROUND(SUM(order_amount) / COUNT(DISTINCT(customer_id)), 2) AS average_acquisition_value
FROM 
    (
        SELECT 
            customer_id,
            MIN(order_date) AS first_order_date,
            order_amount
        FROM 
            orders
        GROUP BY 
            customer_id
    ) AS first_orders
WHERE 
    first_order_date BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    acquisition_month
ORDER BY 
    acquisition_month ASC;

/*
 * Customer Retention
 * 
 * Calculates percentage of customers who return to make another purchase
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
 * Usage Notes:
 * 1. Replace the date ranges with appropriate values for your analysis
 * 2. Adjust column names and table names to match your database schema
 * 3. Add additional customer metrics as needed for your organization
 *
 * Common Extensions:
 * - Add customer demographics
 * - Include customer lifetime value (CLV)
 * - Add churn prediction logic
 */

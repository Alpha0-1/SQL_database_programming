/*
 * File: 8-operational_metrics.sql
 * Description: Calculate operational metrics
 * 
 * This script provides SQL queries to analyze operational data:
 * - Order Fulfillment Metrics
 * -Process Efficiency
 * -Service Level Agreements (SLAs)
 * -Inventory Cycle Time
 */

/*
 * Configuration Section
 * 
 * Modify these values to match your database schema
 */
USE business_intelligence_db;

/*
 * Order Fulfillment Metrics
 * 
 * Provides metrics on order fulfillment performance
 */
SELECT 
    COUNT(order_id) AS total_orders,
    COUNT(CASE WHEN delivery_status = 'delivered' THEN order_id END) AS delivered_orders,
    ROUND(
        (COUNT(CASE WHEN delivery_status = 'delivered' THEN order_id END) / COUNT(order_id)) * 100
        , 2
    ) AS delivery_accuracy,
    ROUND(AVG(delivery_time), 2) AS average_delivery_time
FROM 
    order_fulfillment
WHERE 
    order_date BETWEEN '2023-01-01' AND '2023-12-31';

/*
 * Process Efficiency
 * 
 * Calculates efficiency of operational processes
 */
SELECT 
    process_name,
    total_tasks AS total_operations,
    completed_tasks AS completed_operations,
    ROUND(
        (completed_tasks / total_tasks) * 100
        , 2
    ) AS completion_rate,
    ROUND(
        (processing_time / total_tasks)
        , 2
    ) AS average_processing_time
FROM 
    operational_processes
WHERE 
    process_date BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    process_name
ORDER BY 
    completion_rate DESC;

/*
 * Service Level Agreements (SLAs)
 * 
 * Provides metrics on SLA compliance
 */
SELECT 
    SLA_name,
    COUNT(service_request_id) AS total_requests,
    COUNT(CASE WHEN SLA_compliance = 'Met' THEN service_request_id END) AS SLA_met,
    ROUND(
        (COUNT(CASE WHEN SLA_compliance = 'Met' THEN service_request_id END) / COUNT(*)) * 100
        , 2
    ) AS SLA_compliance_rate
FROM 
    SLA_tracker
WHERE 
    request_date BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    SLA_name
ORDER BY 
    SLA_compliance_rate DESC;

/*
 * Inventory Cycle Time
 * 
 * Calculates time taken to replenish inventory
 */
SELECT 
    product_id,
    COUNT(order_id) AS total_orders,
    ROUND(
        (SUM(order_amount) / COUNT(DISTINCT(warehouse_id)))
        , 2
    ) AS average_stock_turnover,
    ROUND(
        (SUM(order_date - restock_date)) / COUNT(order_id)
        , 0
    ) AS average_cycle_time
FROM 
    inventory_cycle
WHERE 
    order_date BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    product_id
ORDER BY 
    average_cycle_time ASC;

/*
 * Usage Notes:
 * 1. Replace the date ranges with appropriate values for your analysis
 * 2. Adjust column names and table names to match your database schema
 * 3. Add additional operational metrics as needed for your organization
 *
 * Common Extensions:
 * - Add workforce management metrics
 * - Include quality control analysis
 * - Add production line efficiency
 */

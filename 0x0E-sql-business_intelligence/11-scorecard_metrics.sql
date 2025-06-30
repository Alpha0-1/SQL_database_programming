/*
 * File: 11-scorecard_metrics.sql
 * Description: Calculate Balanced Scorecard metrics
 * 
 * This script provides SQL queries to calculate key metrics
 * for a Balanced Scorecard framework.
 */

/*
 * Configuration Section
 * 
 * Modify these values to match your database schema
 */
USE business_intelligence_db;

/*
 * Customer Perspective Metrics
 * 
 * Measures customer satisfaction and retention
 */
SELECT 
    COUNT(DISTINCT(customer_id)) AS total_customers,
    ROUND(
        (COUNT(CASE WHEN (star_rating >= 4) THEN customer_id END) / COUNT(DISTINCT(customer_id))) * 100
        , 2
    ) AS satisfied_customers_percentage,
    ROUND(
        (COUNT(CASE WHEN (star_rating = 5) THEN customer_id END) / COUNT(DISTINCT(customer_id))) * 100
        , 2
    ) AS loyal_customers_percentage
FROM 
    customer_feedback
WHERE 
    feedback_date BETWEEN '2023-01-01' AND '2023-12-31';

/*
 * Financial Perspective Metrics
 * 
 * Measures financial performance
 */
SELECT 
    SUM(revenue) AS total_revenue,
    SUM(expenses) AS total_expenses,
    SUM(profit) AS total_profit,
    ROUND(
        (SUM(profit) / SUM(revenue)) * 100
        , 2
    ) AS profit_margin
FROM 
    financial_results
WHERE 
    reporting_date BETWEEN '2023-01-01' AND '2023-12-31';

/*
 * Internal Process Metrics
 * 
 * Measures operational efficiency
 */
SELECT 
    COUNT(order_id) AS total_orders,
    ROUND(AVG(delivery_time), 2) AS average_delivery_time,
    ROUND(
        (COUNT(CASE WHEN delivery_status = 'delivered' THEN order_id END) / COUNT(order_id)) * 100
        , 2
    ) AS order_accuracy
FROM 
    order_fulfillment
WHERE 
    order_date BETWEEN '2023-01-01' AND '2023-12-31';

/*
 * Learning and Growth Metrics
 * 
 * Measures employee development and innovation
 */
SELECT 
    COUNT(DISTINCT(employee_id)) AS total_employees,
    COUNT(DISTINCT(course_completed)) AS total_courses_completed,
    ROUND(
        (COUNT(DISTINCT(course_completed)) / COUNT(DISTINCT(employee_id))) * 100
        , 2
    ) AS employee_training_completion_rate
FROM 
    employee_learning
WHERE 
    learning_date BETWEEN '2023-01-01' AND '2023-12-31';

/*
 * Usage Notes:
 * 1. Replace the date ranges with appropriate values for your analysis
 * 2. Adjust column names and table names to match your database schema
 * 3. Add additional scorecard metrics as needed for your organization
 *
 * Common Extensions:
 * - Add customer lifetime value (CLV)
 * - Include innovation metrics
 * - Add employee engagement scores
 */

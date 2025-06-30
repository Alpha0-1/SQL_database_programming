/*
 * File: 101-predictive_queries.sql
 * Description: Perform predictive analytics
 * 
 * This script provides SQL queries for predictive analysis:
 * - Sales Forecasting
 * -Customer Churn Prediction
 * -Inventory Demand Forecasting
 */

/*
 * Configuration Section
 * 
 * Modify these values to match your database schema
 */
USE business_intelligence_db;

/*
 * Sales Forecasting
 * 
 * Predicts future sales based on historical trends
 */
WITH 
  historical_sales AS (
    SELECT 
        DATE_TRUNC('month', order_date) AS sales_month,
        SUM(order_amount) AS total_sales
    FROM 
        orders
    WHERE 
        order_date BETWEEN '2022-01-01' AND '2023-12-31'
    GROUP BY 
        sales_month
  ),
  predict AS (
    SELECT 
        sales_month,
        total_sales,
        LAG(total_sales, 1) OVER (ORDER BY sales_month) AS prev_month_sales,
        LAG(total_sales, 2) OVER (ORDER BY sales_month) AS prev_prev_month_sales,
        LAG(total_sales, 3) OVER (ORDER BY sales_month) AS prev_prev_prev_month_sales
    FROM 
        historical_sales
  )
SELECT 
    sales_month + INTERVAL '1 month' AS forecast_month,
    ROUND(
        (prev_month_sales * 0.6) + (prev_prev_month_sales * 0.3) + (prev_prev_prev_month_sales * 0.1)
        , 2
    ) AS forecast_sales
FROM 
    predict
ORDER BY 
    forecast_month ASC;

/*
 * Customer Churn Prediction
 * 
 * Predicts customers at risk of churning
 */
WITH 
  recent_orders AS (
    SELECT 
        customer_id,
        MAX(order_date) AS last_order_date
    FROM 
        orders
    GROUP BY 
        customer_id
  )
SELECT 
    customer_id,
    ROUND(
        CASE
            WHEN (current_date - last_order_date) >= 90 THEN 1.0
            ELSE 0.0
        END
        , 2
    ) AS churn_risk_score
FROM 
    recent_orders
ORDER BY 
    churn_risk_score DESC;

/*
 * Inventory Demand Forecasting
 * 
 * Predicts future inventory needs
 */
WITH 
  historical_demand AS (
    SELECT 
        product_id,
        DATE_TRUNC('month', order_date) AS demand_month,
        COUNT(order_id) AS total_units_sold
    FROM 
        order_items
    WHERE 
        order_date BETWEEN '2022-01-01' AND '2023-12-31'
    GROUP BY 
        product_id, demand_month
  ),
  predict_demand AS (
    SELECT 
        product_id,
        demand_month,
        total_units_sold,
        LAG(total_units_sold, 1) OVER (PARTITION BY product_id ORDER BY demand_month) AS prev_month,
        LAG(total_units_sold, 2) OVER (PARTITION BY product_id ORDER BY demand_month) AS prev_prev_month
    FROM 
        historical_demand
  )
SELECT 
    product_id,
    demand_month + INTERVAL '1 month' AS forecast_month,
    ROUND(
        (prev_month * 0.7) + (prev_prev_month * 0.3)
        , 0
    ) AS forecast_units
FROM 
    predict_demand
ORDER BY 
    product_id, forecast_month ASC;

/*
 * Usage Notes:
 * 1. Replace the date ranges with appropriate values for your analysis
 * 2. Adjust column names and table names to match your database schema
 * 3. Add additional predictive models as needed for your organization
 *
 * Common Extensions:
 * - Add time-series models (ARIMA, LSTM)
 * - Include external factors (seasonality, promotions)
 * - Add confidence intervals
 */

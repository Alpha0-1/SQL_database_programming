/*
 * File: 2-financial_reporting.sql
 * Description: Generate financial reports
 * 
 * This script provides SQL queries to generate key 
 * financial reports:
 * - Income Statement
 * - Balance Sheet
 * - Cash Flow Analysis
 */

/*
 * Configuration Section
 * 
 * Modify these values to match your database schema
 */
USE business_intelligence_db;

/*
 * Income Statement
 * 
 * Provides summary of revenues, expenses, and profits
 */
SELECT 
    'Income Statement' AS report_type,
    SUM(order_amount) AS total_revenue,
    SUM(cost_of_goods) AS cost_of_goods_sold,
    SUM(order_amount - cost_of_goods) AS gross_profit,
    ROUND((SUM(order_amount - cost_of_goods) / SUM(order_amount)) * 100, 2) AS gross_margin_percentage,
    SUM(expenses) AS total_expenses,
    SUM(order_amount - cost_of_goods - expenses) AS net_income
FROM 
    financial_transactions
WHERE 
    transaction_date BETWEEN '2023-01-01' AND '2023-12-31';

/*
 * Balance Sheet
 * 
 * Provides summary of assets, liabilities, and equity
 */
SELECT 
    'Balance Sheet' AS report_type,
    SUM(assets) AS total_assets,
    SUM(liabilities) AS total_liabilities,
    SUM(assets - liabilities) AS equity
FROM 
    balance_sheet_data
WHERE 
    reporting_date BETWEEN '2023-01-01' AND '2023-12-31';

/*
 * Cash Flow Analysis
 * 
 * Provides summary of cash inflows and outflows
 */
SELECT 
    'Cash Flow' AS report_type,
    SUM(cash_inflows) AS total_cash_inflows,
    SUM(cash_outflows) AS total_cash_outflows,
    ROUND(SUM(cash_inflows - cash_outflows) / SUM(cash_inflows) * 100, 2) AS net_cash_flow_percentage
FROM 
    cash_flow_data
WHERE 
    transaction_date BETWEEN '2023-01-01' AND '2023-12-31';

/*
 * Usage Notes:
 * 1. Replace the date ranges with appropriate values for your analysis
 * 2. Adjust column names and table names to match your database schema
 * 3. Add additional financial metrics as needed for your organization
 *
 * Common Extensions:
 * - Add by-time-period breakdowns (daily, weekly, monthly)
 * - Include comparison to previous periods
 * - Add dimension analysis (e.g., by product, region, etc.)
 */

/*
 * File: 6-hr_analytics.sql
 * Description: Perform HR analysis
 * 
 * This script provides SQL queries to analyze HR data:
 * - Employee Turnover
 * -Employee Performance
 * -Salary Distribution
 * -Department Metrics
 */

/*
 * Configuration Section
 * 
 * Modify these values to match your database schema
 */
USE business_intelligence_db;

/*
 * Employee Turnover Analysis
 * 
 * Calculates employee retention and turnover rates
 */
WITH 
  employee_tenure AS (
    SELECT 
        employee_id,
        hire_date,
        CASE
            WHEN termination_date IS NOT NULL THEN termination_date
            ELSE CURRENT_DATE
        END AS tenure_end_date
    FROM 
        employees
  )
SELECT 
    COUNT(*) AS total_employees,
    COUNT(CASE WHEN termination_date IS NOT NULL THEN employee_id END) AS terminated_employees,
    ROUND(
        (COUNT(CASE WHEN termination_date IS NOT NULL THEN employee_id END) / COUNT(*)) * 100
        , 2
    ) AS turnover_rate
FROM 
    employee_tenure;

/*
 * Employee Performance
 * 
 * Provides metrics on employee performance
 */
SELECT 
    employee_id,
    COUNT(project_id) AS total_projects,
    SUM(project_points) AS total_points,
    ROUND(AVG(project_points), 2) AS average_performance
FROM 
    employee_projects
GROUP BY 
    employee_id
ORDER BY 
    total_points DESC;

/*
 * Salary Distribution
 * 
 * Analyzes salary distribution across the organization
 */
SELECT 
    department,
    COUNT(employee_id) AS total_employees,
    ROUND(AVG(salary), 2) AS average_salary,
    MIN(salary) AS minimum_salary,
    MAX(salary) AS maximum_salary
FROM 
    employees
GROUP BY 
    department
ORDER BY 
    average_salary DESC;

/*
 * Department Metrics
 * 
 * Provides high-level metrics for each department
 */
SELECT 
    department,
    COUNT(employee_id) AS headcount,
    ROUND(AVG(salary), 2) AS average_salary,
    COUNT(CASE WHEN termination_date IS NOT NULL THEN employee_id END) AS separations,
    ROUND(
        (COUNT(CASE WHEN termination_date IS NOT NULL THEN employee_id END) / COUNT(*)) * 100
        , 2
    ) AS turnover_rate
FROM 
    employees
GROUP BY 
    department
ORDER BY 
    turnover_rate DESC;

/*
 * Usage Notes:
 * 1. Replace the date ranges with appropriate values for your analysis
 * 2. Adjust column names and table names to match your database schema
 * 3. Add additional HR metrics as needed for your organization
 *
 * Common Extensions:
 * - Add employee performance by manager
 * - Include diversity and inclusion metrics
 * - Add benefits and compensation breakdowns
 */

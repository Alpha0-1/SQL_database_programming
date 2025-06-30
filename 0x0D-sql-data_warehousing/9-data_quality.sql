-- =====================================================
-- File: 9-data_quality.sql
-- Description: Data quality checks and validation procedures
-- Author: Alpha0-1
-- =====================================================

-- Data quality is crucial for reliable analytics and reporting
-- This file demonstrates various data quality patterns and checks

-- =====================================================
-- DATA QUALITY FRAMEWORK SETUP
-- =====================================================

-- Data quality rules configuration table
CREATE TABLE data_quality_rules (
    rule_id INT AUTO_INCREMENT PRIMARY KEY,
    rule_name VARCHAR(100) NOT NULL,
    table_name VARCHAR(100) NOT NULL,
    column_name VARCHAR(100),
    rule_type VARCHAR(50) NOT NULL, -- COMPLETENESS, ACCURACY, CONSISTENCY, VALIDITY
    rule_description TEXT,
    sql_condition TEXT,
    severity VARCHAR(20) DEFAULT 'HIGH', -- HIGH, MEDIUM, LOW
    is_active BOOLEAN DEFAULT TRUE,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Data quality results table
CREATE TABLE data_quality_results (
    result_id INT AUTO_INCREMENT PRIMARY KEY,
    rule_id INT,
    check_date DATE,
    table_name VARCHAR(100),
    total_records INT,
    failed_records INT,
    failure_rate DECIMAL(5,2),
    status VARCHAR(20), -- PASS, FAIL, WARNING
    error_details TEXT,
    check_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (rule_id) REFERENCES data_quality_rules(rule_id)
);

-- Data quality issues tracking
CREATE TABLE data_quality_issues (
    issue_id INT AUTO_INCREMENT PRIMARY KEY,
    rule_id INT,
    table_name VARCHAR(100),
    record_key VARCHAR(100),
    issue_description TEXT,
    issue_data JSON,
    identified_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved_date TIMESTAMP,
    status VARCHAR(20) DEFAULT 'OPEN', -- OPEN, RESOLVED, IGNORED
    FOREIGN KEY (rule_id) REFERENCES data_quality_rules(rule_id)
);

-- =====================================================
-- COMPLETENESS CHECKS
-- =====================================================

-- Check for missing critical data
CREATE OR REPLACE PROCEDURE check_completeness()
BEGIN
    DECLARE rule_count INT;
    
    -- Check customer completeness
    INSERT INTO data_quality_results (rule_id, check_date, table_name, total_records, failed_records, failure_rate, status)
    SELECT 
        1 as rule_id,
        CURRENT_DATE,
        'dim_customer',
        COUNT(*) as total_records,
        SUM(CASE WHEN first_name IS NULL OR first_name = '' THEN 1 ELSE 0 END) as failed_records,
        ROUND((SUM(CASE WHEN first_name IS NULL OR first_name = '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*)), 2) as failure_rate,
        CASE 
            WHEN (SUM(CASE WHEN first_name IS NULL OR first_name = '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) > 5 THEN 'FAIL'
            WHEN (SUM(CASE WHEN first_name IS NULL OR first_name = '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) > 1 THEN 'WARNING'
            ELSE 'PASS'
        END as status
    FROM dim_customer 
    WHERE is_current = 'Y';
    
    -- Check order amount completeness
    INSERT INTO data_quality_results (rule_id, check_date, table_name, total_records, failed_records, failure_rate, status)
    SELECT 
        2 as rule_id,
        CURRENT_DATE,
        'fact_orders',
        COUNT(*) as total_records,
        SUM(CASE WHEN order_amount IS NULL OR order_amount <= 0 THEN 1 ELSE 0 END) as failed_records,
        ROUND((SUM(CASE WHEN order_amount IS NULL OR order_amount <= 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)), 2) as failure_rate,
        CASE 
            WHEN (SUM(CASE WHEN order_amount IS NULL OR order_amount <= 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) > 2 THEN 'FAIL'
            WHEN (SUM(CASE WHEN order_amount IS NULL OR order_amount <= 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) > 0 THEN 'WARNING'
            ELSE 'PASS'
        END as status
    FROM fact_orders
    WHERE load_date = CURRENT_DATE;
    
END;

-- =====================================================
-- ACCURACY CHECKS
-- =====================================================

-- Validate data accuracy against business rules
CREATE OR REPLACE PROCEDURE check_accuracy()
BEGIN
    
    -- Check email format accuracy
    INSERT INTO data_quality_results (rule_id, check_date, table_name, total_records, failed_records, failure_rate, status)
    SELECT 
        3 as rule_id,
        CURRENT_DATE,
        'dim_customer',
        COUNT(*) as total_records,
        SUM(CASE 
            WHEN email IS NOT NULL 
            AND email NOT REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' 
            THEN 1 ELSE 0 END) as failed_records,
        ROUND((SUM(CASE 
            WHEN email IS NOT NULL 
            AND email NOT REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' 
            THEN 1 ELSE 0 END) * 100.0 / COUNT(*)), 2) as failure_rate,
        CASE 
            WHEN (SUM(CASE 
                WHEN email IS NOT NULL 
                AND email NOT REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' 
                THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) > 1 THEN 'FAIL'
            ELSE 'PASS'
        END as status
    FROM dim_customer 
    WHERE is_current = 'Y';
    
    -- Check order amount ranges
    INSERT INTO data_quality_results (rule_id, check_date, table_name, total_records, failed_records, failure_rate, status)
    SELECT 
        4 as rule_id,
        CURRENT_DATE,
        'fact_orders',
        COUNT(*) as total_records,
        SUM(CASE WHEN order_amount > 10000 OR order_amount < 0 THEN 1 ELSE 0 END) as failed_records,
        ROUND((SUM(CASE WHEN order_amount > 10000 OR order_amount < 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)), 2) as failure_rate,
        CASE 
            WHEN (SUM(CASE WHEN order_amount > 10000 OR order_amount < 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) > 0.5 THEN 'FAIL'
            ELSE 'PASS'
        END as status
    FROM fact_orders
    WHERE load_date = CURRENT_DATE;
    
END;

-- =====================================================
-- CONSISTENCY CHECKS
-- =====================================================

-- Check data consistency across related tables
CREATE OR REPLACE PROCEDURE check_consistency()
BEGIN
    
    -- Check referential integrity between facts and dimensions
    INSERT INTO data_quality_results (rule_id, check_date, table_name, total_records, failed_records, failure_rate, status)
    SELECT 
        5 as rule_id,
        CURRENT_DATE,
        'fact_orders',
        COUNT(*) as total_records,
        COUNT(*) - COUNT(dc.customer_key) as failed_records,
        ROUND(((COUNT(*) - COUNT(dc.customer_key)) * 100.0 / COUNT(*)), 2) as failure_rate,
        CASE 
            WHEN ((COUNT(*) - COUNT(dc.customer_key)) * 100.0 / COUNT(*)) > 0 THEN 'FAIL'
            ELSE 'PASS'
        END as status
    FROM fact_orders fo
    LEFT JOIN dim_customer dc ON fo.customer_key = dc.customer_key
    WHERE fo.load_date = CURRENT_DATE;
    
    -- Check for duplicate records in dimensions
    INSERT INTO data_quality_results (rule_id, check_date, table_name, total_records, failed_records, failure_rate, status)
    SELECT 
        6 as rule_id,
        CURRENT_DATE,
        'dim_customer',
        COUNT(*) as total_records,
        COUNT(*) - COUNT(DISTINCT customer_id) as failed_records,
        ROUND(((COUNT(*) - COUNT(DISTINCT customer_id)) * 100.0 / COUNT(*)), 2) as failure_rate,
        CASE 
            WHEN ((COUNT(*) - COUNT(DISTINCT customer_id)) * 100.0 / COUNT(*)) > 0 THEN 'FAIL'
            ELSE 'PASS'
        END as status
    FROM dim_customer 
    WHERE is_current = 'Y';
    
END;

-- =====================================================
-- VALIDITY CHECKS
-- =====================================================

-- Check data validity against predefined rules
CREATE OR REPLACE PROCEDURE check_validity()
BEGIN
    
    -- Check date validity (no future dates for completed orders)
    INSERT INTO data_quality_results (rule_id, check_date, table_name, total_records, failed_records, failure_rate, status)
    SELECT 
        7 as rule_id,
        CURRENT_DATE,
        'fact_orders',
        COUNT(*) as total_records,
        SUM(CASE WHEN dd.full_date > CURRENT_DATE THEN 1 ELSE 0 END) as failed_records,
        ROUND((SUM(CASE WHEN dd.full_date > CURRENT_DATE THEN 1 ELSE 0 END) * 100.0 / COUNT(*)), 2) as failure_rate,
        CASE 
            WHEN (SUM(CASE WHEN dd.full_date > CURRENT_DATE THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) > 0 THEN 'FAIL'
            ELSE 'PASS'
        END as status
    FROM fact_orders fo
    JOIN dim_date dd ON fo.date_key = dd.date_key
    WHERE fo.load_date = CURRENT_DATE;
    
    -- Check customer registration dates
    INSERT INTO data_quality_results (rule_id, check_date, table_name, total_records, failed_records, failure_rate, status)
    SELECT 
        8 as rule_id,
        CURRENT_DATE,
        'dim_customer',
        COUNT(*) as total_records,
        SUM(CASE 
            WHEN registration_date > CURRENT_DATE 
            OR registration_date < '2000-01-01' 
            THEN 1 ELSE 0 END) as failed_records,
        ROUND((SUM(CASE 
            WHEN registration_date > CURRENT_DATE 
            OR registration_date < '2000-01-01' 
            THEN 1 ELSE 0 END) * 100.0 / COUNT(*)), 2) as failure_rate,
        CASE 
            WHEN (SUM(CASE 
                WHEN registration_date > CURRENT_DATE 
                OR registration_date < '2000-01-01' 
                THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) > 0 THEN 'FAIL'
            ELSE 'PASS'
        END as status
    FROM dim_customer 
    WHERE is_current = 'Y';
    
END;

-- =====================================================
-- STATISTICAL OUTLIER DETECTION
-- =====================================================

-- Detect statistical anomalies in data
CREATE OR REPLACE PROCEDURE detect_outliers()
BEGIN
    
    -- Create temporary table for statistical analysis
    CREATE TEMPORARY TABLE order_stats AS
    SELECT 
        AVG(order_amount) as mean_amount,
        STDDEV(order_amount) as std_amount,
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY order_amount) as q1,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY order_amount) as q3
    FROM fact_orders
    WHERE load_date >= CURRENT_DATE - INTERVAL 30 DAY;
    
    -- Identify outliers using IQR method
    INSERT INTO data_quality_issues (rule_id, table_name, record_key, issue_description, issue_data)
    SELECT 
        9 as rule_id,
        'fact_orders',
        CAST(fo.order_key AS CHAR),
        'Statistical outlier detected',
        JSON_OBJECT(
            'order_amount', fo.order_amount,
            'q1', os.q1,
            'q3', os.q3,
            'iqr_lower', os.q1 - 1.5 * (os.q3 - os.q1),
            'iqr_upper', os.q3 + 1.5 * (os.q3 - os.q1)
        )
    FROM fact_orders fo
    CROSS JOIN order_stats os
    WHERE fo.load_date = CURRENT_DATE
    AND (fo.order_amount < os.q1 - 1.5 * (os.q3 - os.q1)
         OR fo.order_amount > os.q3 + 1.5 * (os.q3 - os.q1));
    
    DROP TEMPORARY TABLE order_stats;
    
END;

-- =====================================================
-- DATA PROFILING PROCEDURES
-- =====================================================

-- Generate data profile for a table
CREATE OR REPLACE PROCEDURE profile_table(IN table_name VARCHAR(100))
BEGIN
    
    CREATE TEMPORARY TABLE profile_results (
        column_name VARCHAR(100),
        data_type VARCHAR(50),
        total_count INT,
        null_count INT,
        unique_count INT,
        min_value VARCHAR(255),
        max_value VARCHAR(255),
        avg_length DECIMAL(10,2)
    );
    
    -- This is a simplified example - in practice, you'd use dynamic SQL
    -- to profile any table structure
    IF table_name = 'dim_customer' THEN
        INSERT INTO profile_results
        SELECT 
            'customer_id' as column_name,
            'INT' as data_type,
            COUNT(*) as total_count,
            SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) as null_count,
            COUNT(DISTINCT customer_id) as unique_count,
            CAST(MIN(customer_id) AS CHAR) as min_value,
            CAST(MAX(customer_id) AS CHAR) as max_value,
            NULL as avg_length
        FROM dim_customer
        WHERE is_current = 'Y'
        
        UNION ALL
        
        SELECT 
            'email' as column_name,
            'VARCHAR' as data_type,
            COUNT(*) as total_count,
            SUM(CASE WHEN email IS NULL THEN 1 ELSE 0 END) as null_count,
            COUNT(DISTINCT email) as unique_count,
            MIN(email) as min_value,
            MAX(email) as max_value,
            AVG(LENGTH(email)) as avg_length
        FROM dim_customer
        WHERE is_current = 'Y';
    END IF;
    
    -- Return profiling results
    SELECT * FROM profile_results;
    
    DROP TEMPORARY TABLE profile_results;
    
END;

-- =====================================================
-- COMPREHENSIVE DATA QUALITY ASSESSMENT
-- =====================================================

-- Master procedure to run all data quality checks
CREATE OR REPLACE PROCEDURE run_data_quality_assessment()
BEGIN
    
    -- Log start of data quality assessment
    INSERT INTO etl_log (job_name, table_name, load_date, status)
    VALUES ('data_quality_assessment', 'ALL_TABLES', CURRENT_DATE, 'STARTED');
    
    -- Run all quality checks
    CALL check_completeness();
    CALL check_accuracy();
    CALL check_consistency();
    CALL check_validity();
    CALL detect_outliers();
    
    -- Generate summary report
    CREATE TEMPORARY TABLE quality_summary AS
    SELECT 
        r.rule_name,
        res.table_name,
        res.status,
        res.failure_rate,
        res.failed_records,
        res.total_records,
        r.severity
    FROM data_quality_results res
    JOIN data_quality_rules r ON res.rule_id = r.rule_id
    WHERE res.check_date = CURRENT_DATE
    ORDER BY 
        CASE r.severity 
            WHEN 'HIGH' THEN 1 
            WHEN 'MEDIUM' THEN 2 
            ELSE 3 
        END,
        res.failure_rate DESC;
    
    -- Check overall assessment status
    SELECT 
        COUNT(*) as total_checks,
        SUM(CASE WHEN status = 'PASS' THEN 1 ELSE 0 END) as passed_checks,
        SUM(CASE WHEN status = 'FAIL' THEN 1 ELSE 0 END) as failed_checks,
        SUM(CASE WHEN status = 'WARNING' THEN 1 ELSE 0 END) as warning_checks,
        ROUND(SUM(CASE WHEN status = 'PASS' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as pass_rate
    FROM data_quality_results
    WHERE check_date = CURRENT_DATE;
    
    -- Return detailed summary
    SELECT * FROM quality_summary;
    
    DROP TEMPORARY TABLE quality_summary;
    
    -- Log completion
    INSERT INTO etl_log (job_name, table_name, load_date, status)
    VALUES ('data_quality_assessment', 'ALL_TABLES', CURRENT_DATE, 'COMPLETED');
    
END;

-- =====================================================
-- DATA QUALITY MONITORING VIEWS
-- =====================================================

-- View for data quality dashboard
CREATE VIEW v_data_quality_dashboard AS
SELECT 
    r.rule_name,
    r.table_name,
    r.rule_type,
    r.severity,
    res.check_date,
    res.total_records,
    res.failed_records,
    res.failure_rate,
    res.status,
    CASE 
        WHEN res.status = 'FAIL' AND r.severity = 'HIGH' THEN 'CRITICAL'
        WHEN res.status = 'FAIL' AND r.severity = 'MEDIUM' THEN 'MAJOR'
        WHEN res.status = 'FAIL' AND r.severity = 'LOW' THEN 'MINOR'
        WHEN res.status = 'WARNING' THEN 'WARNING'
        ELSE 'GOOD'
    END as alert_level
FROM data_quality_rules r
LEFT JOIN data_quality_results res ON r.rule_id = res.rule_id
WHERE r.is_active = TRUE
AND (res.check_date = CURRENT_DATE OR res.check_date IS NULL)
ORDER BY 
    CASE alert_level
        WHEN 'CRITICAL' THEN 1
        WHEN 'MAJOR' THEN 2
        WHEN 'MINOR' THEN 3
        WHEN 'WARNING' THEN 4
        ELSE 5
    END,
    res.failure_rate DESC;

-- Trend analysis view
CREATE VIEW v_data_quality_trends AS
SELECT 
    r.rule_name,
    r.table_name,
    res.check_date,
    res.failure_rate,
    LAG(res.failure_rate) OVER (
        PARTITION BY r.rule_id 
        ORDER BY res.check_date
    ) as previous_failure_rate,
    res.failure_rate - LAG(res.failure_rate) OVER (
        PARTITION BY r.rule_id 
        ORDER BY res.check_date
    ) as trend_change
FROM data_quality_rules r
JOIN data_quality_results res ON r.rule_id = res.rule_id
WHERE res.check_date >= CURRENT_DATE - INTERVAL 30 DAY
ORDER BY r.table_name, r.rule_name, res.check_date;

-- =====================================================
-- SAMPLE DATA QUALITY RULES SETUP
-- =====================================================

-- Insert sample data quality rules
INSERT INTO data_quality_rules (rule_name, table_name, column_name, rule_type, rule_description, severity) VALUES
('Customer First Name Completeness', 'dim_customer', 'first_name', 'COMPLETENESS', 'Check for missing first names', 'HIGH'),
('Order Amount Validity', 'fact_orders', 'order_amount', 'VALIDITY', 'Check for valid order amounts', 'HIGH'),
('Email Format Accuracy', 'dim_customer', 'email', 'ACCURACY', 'Validate email format', 'MEDIUM'),
('Order Amount Range Check', 'fact_orders', 'order_amount', 'ACCURACY', 'Check order amount within expected range', 'MEDIUM'),
('Customer Referential Integrity', 'fact_orders', 'customer_key', 'CONSISTENCY', 'Ensure customer exists in dimension', 'HIGH'),
('Customer Uniqueness', 'dim_customer', 'customer_id', 'CONSISTENCY', 'Check for duplicate customers', 'HIGH'),
('Order Date Validity', 'fact_orders', 'date_key', 'VALIDITY', 'Check for valid order dates', 'HIGH'),
('Customer Registration Date', 'dim_customer', 'registration_date', 'VALIDITY', 'Check registration date validity', 'MEDIUM'),
('Order Amount Outliers', 'fact_orders', 'order_amount', 'ACCURACY', 'Detect statistical outliers', 'LOW');

-- =====================================================
-- AUTOMATED DATA REMEDIATION
-- =====================================================

-- Procedure to automatically fix certain data quality issues
CREATE OR REPLACE PROCEDURE auto_remediate_data_issues()
BEGIN
    
    -- Fix email format issues (convert to lowercase)
    UPDATE dim_customer 
    SET email = LOWER(TRIM(email))
    WHERE is_current = 'Y'
    AND email != LOWER(TRIM(email))
    AND email IS NOT NULL;
    
    -- Log remediation action
    INSERT INTO etl_log (job_name, table_name, load_date, records_processed, status)
    VALUES ('auto_remediation', 'dim_customer', CURRENT_DATE, ROW_COUNT(), 'COMPLETED');
    
    -- Fix obvious data entry errors in names
    UPDATE dim_customer 
    SET first_name = INITCAP(LOWER(TRIM(first_name))),
        last_name = INITCAP(LOWER(TRIM(last_name)))
    WHERE is_current = 'Y'
    AND (first_name != INITCAP(LOWER(TRIM(first_name)))
         OR last_name != INITCAP(LOWER(TRIM(last_name))));
    
    -- Update resolved issues
    UPDATE data_quality_issues 
    SET status = 'RESOLVED',
        resolved_date = CURRENT_TIMESTAMP
    WHERE rule_id IN (3, 8) -- Email format and name format rules
    AND status = 'OPEN';
    
END;

-- =====================================================
-- USAGE EXAMPLES AND TESTING
-- =====================================================

-- How to run data quality checks:

-- 1. Run comprehensive assessment
-- CALL run_data_quality_assessment();

-- 2. Check specific quality aspects
-- CALL check_completeness();
-- CALL check_accuracy();

-- 3. View current data quality status
-- SELECT * FROM v_data_quality_dashboard;

-- 4. Analyze trends
-- SELECT * FROM v_data_quality_trends WHERE check_date >= CURRENT_DATE - INTERVAL 7 DAY;

-- 5. Profile a specific table
-- CALL profile_table('dim_customer');

-- 6. Run automatic remediation
-- CALL auto_remediate_data_issues();

-- =====================================================
-- SAMPLE QUERIES FOR DATA QUALITY ANALYSIS
-- =====================================================

-- Get data quality score by table
SELECT 
    table_name,
    COUNT(*) as total_rules,
    SUM(CASE WHEN status = 'PASS' THEN 1 ELSE 0 END) as passed_rules,
    ROUND(SUM(CASE WHEN status = 'PASS' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as quality_score
FROM v_data_quality_dashboard
GROUP BY table_name
ORDER BY quality_score DESC;

-- Identify tables with critical issues
SELECT DISTINCT
    table_name,
    COUNT(*) as critical_issues
FROM v_data_quality_dashboard
WHERE alert_level = 'CRITICAL'
GROUP BY table_name
ORDER BY critical_issues DESC;

-- Track data quality improvements over time
SELECT 
    check_date,
    AVG(CASE WHEN status = 'PASS' THEN 100 ELSE 0 END) as daily_quality_score
FROM data_quality_results
WHERE check_date >= CURRENT_DATE - INTERVAL 30 DAY
GROUP BY check_date
ORDER BY check_date;

-- =====================================================
-- BEST PRACTICES FOR DATA QUALITY
-- =====================================================

/*
1. PROACTIVE APPROACH:
   - Implement data quality checks early in the ETL process
   - Validate data at source systems when possible
   - Use data profiling to understand data patterns

2. COMPREHENSIVE COVERAGE:
   - Check completeness, accuracy, consistency, and validity
   - Include both business rules and technical validations
   - Monitor data quality trends over time

3. SEVERITY-BASED HANDLING:
   - Classify issues by severity (Critical, Major, Minor)
   - Implement appropriate responses for each severity level
   - Focus on high-impact issues first

4. AUTOMATION:
   - Automate routine data quality checks
   - Set up alerts for critical issues
   - Implement auto-remediation for common problems

5. DOCUMENTATION:
   - Document all data quality rules and their rationale
   - Maintain data lineage and impact analysis
   - Keep stakeholders informed of data quality status

6. CONTINUOUS IMPROVEMENT:
   - Regularly review and update quality rules
   - Learn from data quality incidents
   - Involve business users in defining quality standards
*/

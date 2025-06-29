-- =====================================================
-- File: 11-big_data_sql.sql
-- Description: Big data SQL (Spark SQL) patterns
-- Author: Alpha0-1
-- Purpose: Demonstrate SQL for big data processing
-- =====================================================

-- This file demonstrates SQL patterns commonly used in big data environments
-- Examples include Spark SQL, distributed query patterns, and optimization techniques

-- 1. Partitioned table creation (typical in big data systems)
-- Simulate Spark SQL CREATE TABLE syntax
CREATE TABLE IF NOT EXISTS large_events (
    event_id VARCHAR(50),
    user_id VARCHAR(50),
    session_id VARCHAR(50),
    event_type VARCHAR(100),
    event_timestamp TIMESTAMP,
    properties JSONB,
    country VARCHAR(50),
    platform VARCHAR(50),
    app_version VARCHAR(20)
) PARTITION BY RANGE (event_timestamp);

-- Create partitions for different time periods
CREATE TABLE IF NOT EXISTS large_events_2024_q1 PARTITION OF large_events
FOR VALUES FROM ('2024-01-01') TO ('2024-04-01');

CREATE TABLE IF NOT EXISTS large_events_2024_q2 PARTITION OF large_events
FOR VALUES FROM ('2024-04-01') TO ('2024-07-01');

-- 2. Window functions for big data analytics
-- Sample data for demonstration
INSERT INTO large_events (event_id, user_id, session_id, event_type, event_timestamp, properties, country, platform, app_version) VALUES
('evt_001', 'user_001', 'sess_001', 'page_view', '2024-01-15 10:30:00', '{"page": "/home"}', 'US', 'web', '1.0.0'),
('evt_002', 'user_001', 'sess_001', 'click', '2024-01-15 10:31:00', '{"element": "button"}', 'US', 'web', '1.0.0'),
('evt_003', 'user_002', 'sess_002', 'page_view', '2024-01-15 11:00:00', '{"page": "/products"}', 'UK', 'mobile', '1.0.1'),
('evt_004', 'user_001', 'sess_003', 'page_view', '2024-01-16 09:15:00', '{"page": "/home"}', 'US', 'web', '1.0.0'),
('evt_005', 'user_003', 'sess_004', 'signup', '2024-01-16 14:20:00', '{"source": "organic"}', 'CA', 'mobile', '1.0.1');

-- User journey analysis with window functions
WITH user_sessions AS (
    SELECT 
        user_id,
        session_id,
        event_timestamp,
        event_type,
        properties,
        -- Session sequence number for each user
        ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY event_timestamp) as user_event_seq,
        -- Time between events for the same user
        LAG(event_timestamp) OVER (PARTITION BY user_id ORDER BY event_timestamp) as prev_event_time,
        -- First and last event timestamps in session
        FIRST_VALUE(event_timestamp) OVER (PARTITION BY session_id ORDER BY event_timestamp) as session_start,
        LAST_VALUE(event_timestamp) OVER (PARTITION BY session_id ORDER BY event_timestamp 
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) as session_end
    FROM large_events
)
SELECT 
    user_id,
    session_id,
    COUNT(*) as events_in_session,
    MIN(event_timestamp) as session_start,
    MAX(event_timestamp) as session_end,
    EXTRACT(EPOCH FROM (MAX(event_timestamp) - MIN(event_timestamp)))/60 as session_duration_minutes,
    string_agg(event_type, ' -> ' ORDER BY event_timestamp) as event_sequence
FROM user_sessions
GROUP BY user_id, session_id
ORDER BY user_id, session_start;

-- 3. Cohort analysis pattern (common in big data analytics)
WITH user_first_activity AS (
    -- Find first activity date for each user
    SELECT 
        user_id,
        DATE(MIN(event_timestamp)) as cohort_date
    FROM large_events
    WHERE event_type = 'signup'
    GROUP BY user_id
),
user_monthly_activity AS (
    -- Track monthly activity for each user
    SELECT DISTINCT
        e.user_id,
        DATE_TRUNC('month', e.event_timestamp) as activity_month
    FROM large_events e
    INNER JOIN user_first_activity ufa ON e.user_id = ufa.user_id
),
cohort_data AS (
    SELECT 
        ufa.cohort_date,
        uma.activity_month,
        COUNT(DISTINCT uma.user_id) as active_users,
        EXTRACT(MONTH FROM AGE(uma.activity_month, ufa.cohort_date)) as month_number
    FROM user_first_activity ufa
    LEFT JOIN user_monthly_activity uma ON ufa.user_id = uma.user_id
    GROUP BY ufa.cohort_date, uma.activity_month
)
SELECT 
    cohort_date,
    month_number,
    active_users,
    ROUND(100.0 * active_users / FIRST_VALUE(active_users) 
          OVER (PARTITION BY cohort_date ORDER BY month_number), 2) as retention_rate
FROM cohort_data
WHERE month_number IS NOT NULL
ORDER BY cohort_date, month_number;

-- 4. Funnel analysis with arrays (useful for event sequences)
CREATE TABLE IF NOT EXISTS funnel_steps (
    id SERIAL PRIMARY KEY,
    funnel_name VARCHAR(100),
    step_order INTEGER,
    step_name VARCHAR(100),
    event_criteria JSONB
);

INSERT INTO funnel_steps (funnel_name, step_order, step_name, event_criteria) VALUES
('user_onboarding', 1, 'signup', '{"event_type": "signup"}'),
('user_onboarding', 2, 'first_login', '{"event_type": "login"}'),
('user_onboarding', 3, 'profile_complete', '{"event_type": "profile_update"}');

-- Funnel analysis query
WITH user_events_ordered AS (
    SELECT 
        user_id,
        event_type,
        event_timestamp,
        ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY event_timestamp) as event_order
    FROM large_events
),
funnel_completion AS (
    SELECT 
        user_id,
        CASE WHEN array_position(array_agg(event_type ORDER BY event_timestamp), 'signup') IS NOT NULL THEN 1 ELSE 0 END as completed_signup,
        CASE WHEN array_position(array_agg(event_type ORDER BY event_timestamp), 'login') > 
                  array_position(array_agg(event_type ORDER BY event_timestamp), 'signup') THEN 1 ELSE 0 END as completed_login,
        CASE WHEN array_position(array_agg(event_type ORDER BY event_timestamp), 'profile_update') > 
                  array_position(array_agg(event_type ORDER BY event_timestamp), 'login') THEN 1 ELSE 0 END as completed_profile
    FROM user_events_ordered
    GROUP BY user_id
)
SELECT 
    'Step 1: Signup' as step,
    SUM(completed_signup) as users,
    ROUND(100.0 * SUM(completed_signup) / COUNT(*), 2) as conversion_rate
FROM funnel_completion
UNION ALL
SELECT 
    'Step 2: First Login' as step,
    SUM(completed_login) as users,
    ROUND(100.0 * SUM(completed_login) / SUM(completed_signup), 2) as conversion_rate
FROM funnel_completion
WHERE completed_signup = 1
UNION ALL
SELECT 
    'Step 3: Profile Complete' as step,
    SUM(completed_profile) as users,
    ROUND(100.0 * SUM(completed_profile) / SUM(completed_login), 2) as conversion_rate
FROM funnel_completion
WHERE completed_login = 1;

-- 5. Advanced aggregations for big data
-- Daily, weekly, monthly rollups
CREATE MATERIALIZED VIEW IF NOT EXISTS event_rollups AS
WITH daily_stats AS (
    SELECT 
        DATE(event_timestamp) as date,
        country,
        platform,
        app_version,
        event_type,
        COUNT(*) as event_count,
        COUNT(DISTINCT user_id) as unique_users,
        COUNT(DISTINCT session_id) as unique_sessions
    FROM large_events
    GROUP BY DATE(event_timestamp), country, platform, app_version, event_type
),
weekly_stats AS (
    SELECT 
        DATE_TRUNC('week', date) as week_start,
        country,
        platform,
        'weekly' as granularity,
        SUM(event_count) as total_events,
        AVG(unique_users) as avg_daily_users,
        SUM(unique_sessions) as total_sessions
    FROM daily_stats
    GROUP BY DATE_TRUNC('week', date), country, platform
),
monthly_stats AS (
    SELECT 
        DATE_TRUNC('month', date) as month_start,
        country,
        platform,
        'monthly' as granularity,
        SUM(event_count) as total_events,
        AVG(unique_users) as avg_daily_users,
        SUM(unique_sessions) as total_sessions
    FROM daily_stats
    GROUP BY DATE_TRUNC('month', date), country, platform
)
SELECT 
    date as period_start,
    country,
    platform,
    'daily' as granularity,
    event_count as total_events,
    unique_users as avg_daily_users,
    unique_sessions as total_sessions
FROM daily_stats
UNION ALL
SELECT week_start, country, platform, granularity, total_events, avg_daily_users, total_sessions FROM weekly_stats
UNION ALL
SELECT month_start, country, platform, granularity, total_events, avg_daily_users, total_sessions FROM monthly_stats;

-- 6. Approximate algorithms for big data (using PostgreSQL extensions)
-- HyperLogLog for approximate distinct counts
CREATE EXTENSION IF NOT EXISTS hll;

CREATE TABLE IF NOT EXISTS approximate_metrics (
    id SERIAL PRIMARY KEY,
    metric_date DATE,
    metric_name VARCHAR(100),
    dimension_1 VARCHAR(100),
    dimension_2 VARCHAR(100),
    hll_sketch HLL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Function to update HLL sketches
CREATE OR REPLACE FUNCTION update_approximate_metrics()
RETURNS VOID AS $$
BEGIN
    INSERT INTO approximate_metrics (metric_date, metric_name, dimension_1, dimension_2, hll_sketch)
    SELECT 
        CURRENT_DATE,
        'unique_users',
        country,
        platform,
        hll_add_agg(hll_hash_text(user_id))
    FROM large_events
    WHERE DATE(event_timestamp) = CURRENT_DATE
    GROUP BY country, platform
    ON CONFLICT DO NOTHING;
END;
$$ LANGUAGE plpgsql;

-- Query approximate distinct counts
SELECT 
    metric_date,
    dimension_1 as country,
    dimension_2 as platform,
    hll_cardinality(hll_sketch)::BIGINT as approximate_unique_users
FROM approximate_metrics
WHERE metric_name = 'unique_users'
ORDER BY metric_date DESC, country, platform;

-- 7. Time series analysis patterns
-- Moving averages and trend analysis
WITH daily_metrics AS (
    SELECT 
        DATE(event_timestamp) as metric_date,
        COUNT(*) as daily_events,
        COUNT(DISTINCT user_id) as daily_users
    FROM large_events
    GROUP BY DATE(event_timestamp)
),
metrics_with_trends AS (
    SELECT 
        metric_date,
        daily_events,
        daily_users,
        AVG(daily_events) OVER (
            ORDER BY metric_date 
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ) as events_7day_avg,
        AVG(daily_users) OVER (
            ORDER BY metric_date 
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ) as users_7day_avg,
        LAG(daily_events, 7) OVER (ORDER BY metric_date) as events_week_ago
    FROM daily_metrics
)
SELECT 
    metric_date,
    daily_events,
    ROUND(events_7day_avg, 2) as events_7day_avg,
    CASE 
        WHEN events_week_ago IS NOT NULL 
        THEN ROUND(100.0 * (daily_events - events_week_ago) / events_week_ago, 2)
        ELSE NULL 
    END as week_over_week_growth_percent
FROM metrics_with_trends
ORDER BY metric_date;

-- 8. Data skew handling patterns
-- Identify and handle data skew
WITH user_event_distribution AS (
    SELECT 
        user_id,
        COUNT(*) as event_count,
        NTILE(100) OVER (ORDER BY COUNT(*)) as percentile
    FROM large_events
    GROUP BY user_id
)
SELECT 
    percentile,
    MIN(event_count) as min_events,
    MAX(event_count) as max_events,
    AVG(event_count) as avg_events,
    COUNT(*) as users_in_percentile
FROM user_event_distribution
GROUP BY percentile
HAVING percentile IN (50, 90, 95, 99)
ORDER BY percentile;

-- 9. Streaming analytics simulation
-- Create table for real-time metrics
CREATE TABLE IF NOT EXISTS streaming_metrics (
    id SERIAL PRIMARY KEY,
    window_start TIMESTAMP,
    window_end TIMESTAMP,
    metric_name VARCHAR(100),
    metric_value NUMERIC,
    dimensions JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Function to simulate streaming window calculations
CREATE OR REPLACE FUNCTION calculate_streaming_metrics(
    p_window_minutes INTEGER DEFAULT 5
)
RETURNS INTEGER AS $$
DECLARE
    window_start TIMESTAMP;
    window_end TIMESTAMP;
    inserted_count INTEGER := 0;
BEGIN
    window_end := DATE_TRUNC('minute', CURRENT_TIMESTAMP);
    window_start := window_end - INTERVAL '1 minute' * p_window_minutes;
    
    -- Calculate metrics for the window
    INSERT INTO streaming_metrics (window_start, window_end, metric_name, metric_value, dimensions)
    SELECT 
        window_start,
        window_end,
        'events_per_minute',
        COUNT(*)::NUMERIC / p_window_minutes,
        json_build_object('country', country, 'platform', platform)
    FROM large_events
    WHERE event_timestamp BETWEEN window_start AND window_end
    GROUP BY country, platform;
    
    GET DIAGNOSTICS inserted_count = ROW_COUNT;
    
    -- Clean up old streaming metrics
    DELETE FROM streaming_metrics 
    WHERE created_at < CURRENT_TIMESTAMP - INTERVAL '1 hour';
    
    RETURN inserted_count;
END;
$$ LANGUAGE plpgsql;

-- 10. Performance optimization hints (PostgreSQL specific)
-- Optimize for big data queries
SET work_mem = '256MB';
SET maintenance_work_mem = '1GB';
SET effective_cache_size = '4GB';

-- Create columnar indexes for analytical queries
CREATE INDEX IF NOT EXISTS idx_large_events_country_time 
ON large_events(country, event_timestamp) 
WHERE event_timestamp >= CURRENT_DATE - INTERVAL '90 days';

CREATE INDEX IF NOT EXISTS idx_large_events_type_user 
ON large_events(event_type, user_id);

-- Partial index for recent data
CREATE INDEX IF NOT EXISTS idx_large_events_recent 
ON large_events(event_timestamp, user_id, event_type)
WHERE event_timestamp >= CURRENT_DATE - INTERVAL '30 days';

-- 11. Data sampling for big data analysis
-- Random sampling function
CREATE OR REPLACE FUNCTION sample_events(sample_rate FLOAT)
RETURNS TABLE(
    event_id VARCHAR(50),
    user_id VARCHAR(50),
    event_type VARCHAR(100),
    event_timestamp TIMESTAMP,
    properties JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        e.event_id,
        e.user_id,
        e.event_type,
        e.event_timestamp,
        e.properties
    FROM large_events e
    WHERE random() < sample_rate
    ORDER BY e.event_timestamp;
END;
$$ LANGUAGE plpgsql;

-- Use sampling for quick analysis
SELECT 
    event_type,
    COUNT(*) as sampled_count,
    ROUND(COUNT(*) / 0.01) as estimated_total  -- Assuming 1% sample
FROM sample_events(0.01)
GROUP BY event_type;

-- 12. Batch processing patterns
-- Create batch processing jobs table
CREATE TABLE IF NOT EXISTS batch_processing_jobs (
    id SERIAL PRIMARY KEY,
    job_name VARCHAR(200),
    job_type VARCHAR(100),
    parameters JSONB,
    status VARCHAR(50) DEFAULT 'pending',
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    records_processed BIGINT DEFAULT 0,
    error_details TEXT
);

-- Example batch job: Daily aggregation
INSERT INTO batch_processing_jobs (job_name, job_type, parameters) VALUES
('daily_user_stats', 'aggregation', 
 '{"target_date": "2024-01-15", "tables": ["large_events"], "output_table": "daily_user_stats"}');

-- Refresh materialized views
REFRESH MATERIALIZED VIEW event_rollups;

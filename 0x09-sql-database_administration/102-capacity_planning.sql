-- 102-capacity_planning.sql
-- Purpose: Plan database growth and capacity needs

-- Estimate table growth over time
SELECT relname AS table_name,
       pg_total_relation_size(relid) AS total_size,
       pg_size_pretty(pg_total_relation_size(relid)) AS pretty_size,
       reltuples AS row_count
FROM pg_stat_user_tables
ORDER BY reltuples DESC;

-- Forecast storage growth based on historical data
-- Assuming you track daily size changes:
CREATE TABLE daily_growth (
    date DATE PRIMARY KEY,
    size BIGINT
);

-- Insert sample data
INSERT INTO daily_growth VALUES ('2025-04-01', 100000000);
INSERT INTO daily_growth VALUES ('2025-04-02', 105000000);
INSERT INTO daily_growth VALUES ('2025-04-03', 110250000);

-- Predict next week's size (simple linear model)
SELECT date + interval '1 day' AS forecast_date,
       AVG(size) OVER (ORDER BY date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS predicted_size
FROM daily_growth;

-- Alert when approaching storage limit
DO $$
DECLARE
    current_size BIGINT := pg_database_size('company_db');
    warning_limit BIGINT := 90 * 1024 * 1024 * 1024; -- 90 GB
BEGIN
    IF current_size > warning_limit THEN
        RAISE NOTICE 'Storage nearing capacity: %', pg_size_pretty(current_size);
    END IF;
END;
$$;

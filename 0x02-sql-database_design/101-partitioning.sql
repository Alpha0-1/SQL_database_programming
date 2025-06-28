-- 101-partitioning.sql: Table Partitioning Strategy

-- Partitioning improves performance on large datasets

-- Range partitioning by date
CREATE TABLE IF NOT EXISTS logs (
    log_id SERIAL,
    message TEXT,
    created_at DATE NOT NULL
) PARTITION BY RANGE (created_at);

-- Create partitions
CREATE TABLE IF NOT EXISTS logs_2024 PARTITION OF logs
    FOR VALUES FROM ('2024-01-01') TO ('2024-12-31');

-- Insert data
INSERT INTO logs (message, created_at) VALUES ('Test', '2024-05-01');

-- Query specific partition
SELECT * FROM logs_2024;

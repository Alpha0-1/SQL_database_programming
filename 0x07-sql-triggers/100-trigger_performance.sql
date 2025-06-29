-- 100-trigger_performance.sql
-- Discussing performance aspects of triggers
-- Avoid unnecessary logic, indexing relevant columns, minimal data manipulation inside trigger

-- Example for performance-conscious trigger
CREATE TABLE metrics (
    metric_id INT PRIMARY KEY,
    value INT
);

CREATE TABLE metric_log (
    metric_id INT,
    log_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DELIMITER //
CREATE TRIGGER trg_metric_insert
AFTER INSERT ON metrics
FOR EACH ROW
BEGIN
    -- Lightweight logging
    INSERT INTO metric_log (metric_id) VALUES (NEW.metric_id);
END;//
DELIMITER ;

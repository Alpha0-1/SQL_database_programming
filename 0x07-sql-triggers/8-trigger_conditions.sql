-- 8-trigger_conditions.sql
-- Trigger with specific condition inside

CREATE TABLE alerts (
    alert_id INT PRIMARY KEY,
    severity VARCHAR(10)
);

CREATE TABLE critical_logs (
    alert_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DELIMITER //
CREATE TRIGGER trg_critical_alert
AFTER INSERT ON alerts
FOR EACH ROW
BEGIN
    IF NEW.severity = 'critical' THEN
        INSERT INTO critical_logs (alert_id) VALUES (NEW.alert_id);
    END IF;
END;//
DELIMITER ;

INSERT INTO alerts VALUES (1, 'info'), (2, 'critical');
SELECT * FROM critical_logs;


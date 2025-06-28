-- 10-triggers.sql: Trigger Implementation

-- Triggers perform actions automatically when certain events occur

-- Log user deletions
CREATE TABLE IF NOT EXISTS user_log (
    log_id SERIAL PRIMARY KEY,
    user_id INT,
    action TEXT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Function to be called by trigger
CREATE OR REPLACE FUNCTION log_user_delete()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO user_log (user_id, action)
    VALUES (OLD.user_id, 'deleted');
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger
CREATE TRIGGER trg_log_user_delete
AFTER DELETE ON users
FOR EACH ROW EXECUTE FUNCTION log_user_delete();

-- Test trigger
DELETE FROM users WHERE user_id = 1;
SELECT * FROM user_log;

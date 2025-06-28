-- 10-date_functions.sql
-- Purpose: Demonstrate date and time functions
-- Author: Alpha0-1

-- Table of events
CREATE TABLE IF NOT EXISTS events (
    event_name VARCHAR(100),
    event_date TIMESTAMP
);

-- Insert sample data
INSERT INTO events (event_name, event_date) VALUES
('Conference', NOW() - INTERVAL '5 days'),
('Meeting', NOW() - INTERVAL '1 day'),
('Workshop', NOW());

-- Extract parts of dates
SELECT
    event_name,
    event_date,
    EXTRACT(YEAR FROM event_date) AS year,
    EXTRACT(MONTH FROM event_date) AS month,
    EXTRACT(DAY FROM event_date) AS day
FROM events;

-- Add intervals
SELECT
    event_name,
    event_date,
    event_date + INTERVAL '7 days' AS reminder_date
FROM events;

-- Age calculation
SELECT
    event_name,
    AGE(event_date) AS age_since_event
FROM events;

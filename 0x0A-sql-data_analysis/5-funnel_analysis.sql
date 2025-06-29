-- File: 5-funnel_analysis.sql
-- Description: Track conversion funnel stages

-- Create a mock funnel table
CREATE TABLE IF NOT EXISTS funnel (
    user_id INT,
    stage VARCHAR(50),
    timestamp TIMESTAMP
);

-- Funnel conversion count by stage
SELECT 
    stage,
    COUNT(DISTINCT user_id) AS users_at_stage
FROM 
    funnel
GROUP BY 
    stage
ORDER BY 
    stage;

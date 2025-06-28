-- 8-cities_of_california_subquery.sql
-- Get cities in California using subquery

-- Subquery: Find state_id where name = 'California', then get cities
SELECT c.name
FROM cities c
WHERE c.state_id = (
    SELECT s.id
    FROM states s
    WHERE s.name = 'California'
);

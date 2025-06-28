
-- 9-cities_by_state_join.sql
-- Join example between cities and states

-- INNER JOIN to get city names and their corresponding state
SELECT c.name AS city, s.name AS state
FROM cities c
JOIN states s ON c.state_id = s.id;

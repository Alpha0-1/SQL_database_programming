-- Get top 3 cities by temperature

SELECT city, temperature
FROM temperatures
ORDER BY temperature DESC
LIMIT 3;

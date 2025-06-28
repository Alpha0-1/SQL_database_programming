-- Calculate average temperature grouped by city

SELECT city, AVG(temperature) AS avg_temperature
FROM temperatures
GROUP BY city;

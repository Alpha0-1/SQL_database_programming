-- Find maximum temperature by state

SELECT state, MAX(temperature) AS max_temp
FROM temperatures
GROUP BY state;

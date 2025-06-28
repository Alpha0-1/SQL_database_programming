-- EXISTS and NOT EXISTS example

-- Salespersons who have made at least one sale in the 'East' region
SELECT DISTINCT salesperson
FROM sales_data s
WHERE EXISTS (
    SELECT 1 FROM sales_data WHERE region = 'East' AND salesperson = s.salesperson
);

-- Salespersons with no sales in 'West'
SELECT DISTINCT salesperson
FROM sales_data s
WHERE NOT EXISTS (
    SELECT 1 FROM sales_data WHERE region = 'West' AND salesperson = s.salesperson
);

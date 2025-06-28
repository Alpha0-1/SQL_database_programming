-- Using a correlated subquery

SELECT 
    salesperson,
    region,
    sales_amount
FROM sales_data s1
WHERE sales_amount > (
    SELECT AVG(sales_amount)
    FROM sales_data s2
    WHERE s1.region = s2.region
);
